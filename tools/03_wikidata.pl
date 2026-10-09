# Passo 3: dados públicos de jogadores e clubes no Wikidata (CC0).
# Jogador: nascimento, posição detalhada, nacionalidade esportiva, altura, número de artigos na Wikipédia
#          e jogos pela seleção principal (sinais usados para estimar a força).
# Clube: cidade, estádio, capacidade, fundação e número de artigos.
# Saída: db/wikidata.json
use strict; use warnings; use utf8; use FindBin; require "$FindBin::Bin/lib.pl";
binmode STDOUT, ':utf8'; $| = 1;

my $ligas = W::load('db/ligas.json');
my $elencos = W::load('db/elencos.json');

# Títulos de artigos dos jogadores -> QID
my %title; $title{$_->{link}} = 1 for grep { $_->{link} } map { @{ $_->{players} } } values %$elencos;
my @titles = sort keys %title; my %qid;
for (my $i = 0; $i < @titles; $i += 50) {
  my @c = @titles[$i .. ($i + 49 < $#titles ? $i + 49 : $#titles)];
  my $d = W::wiki('en', action => 'query', prop => 'pageprops', ppprop => 'wikibase_item', redirects => 1, titles => join('|', @c));
  my %to = map { $_->{from} => $_->{to} } @{ $d->{query}{normalized} // [] }, @{ $d->{query}{redirects} // [] };
  my %pq = map { $_->{title} => $_->{pageprops}{wikibase_item} } grep { $_->{pageprops} } @{ $d->{query}{pages} };
  for my $t (@c) { my $x = $t; $x = $to{$x} while $to{$x}; $qid{$t} = $pq{$x} if $pq{$x} }
}
printf "jogadores com artigo: %d de %d\n", scalar(keys %qid), scalar @titles;

# Seleções principais masculinas (para contar jogos pela seleção)
my %nt;
for my $b (@{ W::sparql(q{SELECT ?t ?l WHERE { ?t wdt:P31 wd:Q6979593 . ?t rdfs:label ?l . FILTER(LANG(?l) = "en")
  FILTER(!REGEX(?l, "under|U-?[0-9]{2}|olympic|women|B team|amateur|futsal|beach|youth|junior|students|military|universit|unofficial|XI", "i")) }}) }) {
  (my $q = $b->{t}{value}) =~ s/.*\///; $nt{$q} = $b->{l}{value};
}
printf "seleções principais: %d\n", scalar keys %nt;

my $ents = W::entities([sort { $a cmp $b } keys %{ { map { $_ => 1 } values %qid } }], 'claims|sitelinks');
my (%players, %posq);
for my $q (keys %$ents) {
  my $e = $ents->{$q}; my $cl = $e->{claims} // {};
  my $v = sub { my ($p) = @_; map { $_->{mainsnak}{datavalue}{value} // () } grep { $_->{rank} ne 'deprecated' } @{ $cl->{$p} // [] } };
  my ($birth) = map { $_->{time} } $v->('P569');
  my @pos = map { $_->{id} } $v->('P413'); $posq{$_} = 1 for @pos;
  my ($nat) = map { $_->{id} } $v->('P1532'); ($nat) = map { $_->{id} } $v->('P27') unless $nat;
  my ($h) = map { my $a = $_->{amount}; $a =~ s/^\+//; $_->{unit} =~ /Q11573$/ ? $a * 100 : $a } $v->('P2048');
  my ($caps, $natTeam) = (0, '');
  for my $st (@{ $cl->{P54} // [] }) {
    my $t = $st->{mainsnak}{datavalue}{value}{id} // next;
    next unless $nt{$t};
    my ($n) = map { $_->{datavalue}{value}{amount} } @{ $st->{qualifiers}{P1350} // [] };
    $n =~ s/^\+// if defined $n;
    $caps += defined $n ? $n : 3; $natTeam = $nt{$t};
  }
  $players{$q} = {birth => $birth ? substr($birth, 1, 10) : undef, pos => \@pos, nat => $nat, height => $h,
    links => scalar keys %{ $e->{sitelinks} // {} }, caps => $caps + 0, natTeam => $natTeam};
}
# Rótulos das posições e dos países (para traduzir)
my %lab;
my @need = (keys %posq, grep { $_ } map { $_->{nat} } values %players);
my $le = W::entities([sort keys %{ { map { $_ => 1 } @need } }], 'labels|claims');
for my $q (keys %$le) {
  $lab{$q} = {en => $le->{$q}{labels}{en}{value}, pt => $le->{$q}{labels}{pt}{value},
    fifa => (map { $_->{mainsnak}{datavalue}{value} // () } @{ $le->{$q}{claims}{P3441} // [] })[0]};
}

# Clubes
my @cq = map { $_->{qid} } map { @{ $_->{clubs} } } @$ligas;
my $ce = W::entities(\@cq, 'claims|sitelinks|labels');
my (%clubs, %place);
for my $q (@cq) {
  my $cl = $ce->{$q}{claims} // {};
  my $v = sub { map { $_->{mainsnak}{datavalue}{value} // () } @{ $cl->{$_[0]} // [] } };
  my ($city) = map { $_->{id} } $v->('P159'); ($city) = map { $_->{id} } $v->('P131') unless $city;
  my ($ven) = map { $_->{id} } $v->('P115');
  my ($inc) = map { substr($_->{time}, 1, 4) } $v->('P571');
  $clubs{$q} = {city => $city, venue => $ven, founded => $inc, links => scalar keys %{ $ce->{$q}{sitelinks} // {} },
    label => $ce->{$q}{labels}{pt}{value} // $ce->{$q}{labels}{en}{value}};
  $place{$_} = 1 for grep { $_ } $city, $ven;
}
my $pe = W::entities([sort keys %place], 'labels|claims');
for my $q (keys %$pe) {
  my ($cap) = map { my $a = $_->{mainsnak}{datavalue}{value}{amount} // 0; $a =~ s/^\+//; $a } @{ $pe->{$q}{claims}{P1083} // [] };
  $lab{$q} = {en => $pe->{$q}{labels}{en}{value}, pt => $pe->{$q}{labels}{pt}{value}, es => $pe->{$q}{labels}{es}{value}, cap => $cap};
}
W::save('db/wikidata.json', {players => \%players, title2qid => \%qid, clubs => \%clubs, labels => \%lab});
printf "jogadores: %d · clubes: %d · rótulos: %d\n", scalar keys %players, scalar keys %clubs, scalar keys %lab;
