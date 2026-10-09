# Passo 5: gera os arquivos de dados do jogo a partir de db/wifoot-db.json.
#   data.js       -> versão comercial: clubes, estádios, jogadores, ligas e copas com nomes fictícios
#                    (mesmas forças, idades, posições, nacionalidades e capacidades do banco real).
#   data_real.js  -> pacote opcional com os nomes reais (distribuição gratuita, separada do app).
use strict; use warnings; use utf8; use FindBin; require "$FindBin::Bin/lib.pl";
use List::Util qw(shuffle); use JSON::PP;
binmode STDOUT, ':utf8'; $| = 1;

my $db = W::load('db/wifoot-db.json');
my %byClub; push @{ $byClub{$_->{club}} }, $_ for @{ $db->{players} };
my %lgInfo = map { ("$_->{id}-$_->{tier}" => $_) } @{ $db->{leagues} };

# Regras de cada país no jogo: acesso/rebaixamento e nome da copa nacional (real e fictício)
my %PAIS = (
  GB1 => [3, 'FA Cup', 'Copa da Inglaterra'], ES1 => [3, 'Copa del Rey', 'Copa da Espanha'], IT1 => [3, 'Coppa Italia', 'Copa da Itália'],
  L1 => [2, 'DFB-Pokal', 'Copa da Alemanha'], FR1 => [2, 'Coupe de France', 'Copa da França'], PO1 => [2, 'Taça de Portugal', 'Taça de Portugal'],
  NL1 => [2, 'KNVB Beker', 'Copa da Holanda'], BE1 => [2, 'Copa da Bélgica', 'Copa da Bélgica'], TR1 => [3, 'Copa da Turquia', 'Copa da Turquia'],
  SC1 => [1, 'Scottish Cup', 'Copa da Escócia'], BR1 => [4, 'Copa do Brasil', 'Copa Nacional do Brasil'], AR1 => [2, 'Copa Argentina', 'Copa Nacional da Argentina'],
);

# ---------- nomes fictícios ----------
srand(20261009);
my %realName = map { lc($_->{name}) => 1 } @{ $db->{players} };
$realName{lc $_->{name}} = 1 for @{ $db->{clubs} };
my (%first, %last, %mono);
for my $p (@{ $db->{players} }) {
  my @w = split /\s+/, $p->{name};
  if (@w == 1) { $mono{$p->{nat}}{$w[0]} = 1; next }
  next if $p->{name} =~ /[.()]/;
  $first{$p->{nat}}{$w[0]} = 1; $last{$p->{nat}}{$w[-1]} = 1;
}
my %pool = map { my $n = $_; ($n => {f => [sort keys %{ $first{$n} }], l => [sort keys %{ $last{$n} }], m => [sort keys %{ $mono{$n} // {} }]}) } keys %first;
my $any = {f => [map { @{ $_->{f} } } values %pool], l => [map { @{ $_->{l} } } values %pool], m => []};
my %usedName;
sub fake_player {
  my ($nat) = @_;
  my $p = $pool{$nat} && @{ $pool{$nat}{f} } >= 8 && @{ $pool{$nat}{l} } >= 8 ? $pool{$nat} : $any;
  for (1 .. 50) {
    my $n = (@{ $p->{m} } >= 15 && rand() < .3) ? $p->{m}[rand @{ $p->{m} }] . (rand() < .5 ? 'inho' : '')
      : $p->{f}[rand @{ $p->{f} }] . ' ' . $p->{l}[rand @{ $p->{l} }];
    next if $realName{lc $n} || $usedName{$n}++;
    return $n;
  }
  return $p->{f}[rand @{ $p->{f} }] . ' ' . $p->{l}[rand @{ $p->{l} }] . ' ' . $p->{l}[rand @{ $p->{l} }];
}
my %LANG = (BR1 => 'pt', PO1 => 'pt', GB1 => 'en', SC1 => 'en', US1 => 'en', IT1 => 'it', L1 => 'de', AT1 => 'de', CH1 => 'de',
  FR1 => 'fr', BE1 => 'fr', NL1 => 'nl', TR1 => 'tr', map { $_ => 'es' } qw(ES1 AR1 UY1 CO1 CL1 PY1 EC1 PE1 BO1 VE1 MX1));
my %PAT = (
  pt => ['%s Futebol Clube', 'Esporte Clube %s', 'Atlético %s', 'União %s', '%s Esporte Clube', 'Associação %s', 'Sport Club %s', 'Clube Atlético %s', 'Grêmio %s'],
  es => ['Club Deportivo %s', 'Atlético %s', 'Unión %s', 'Deportivo %s', 'Sporting %s', '%s Fútbol Club', 'Club Social %s', 'Juventud %s', 'Centro Atlético %s'],
  en => ['%s Athletic', '%s Rovers', '%s Town', '%s Wanderers', '%s Albion', 'AFC %s', '%s Borough', '%s Harriers', '%s Rangers FC'],
  it => ['US %s', '%s Calcio', 'AS %s', 'Polisportiva %s', 'SS %s', 'Virtus %s', 'Sporting %s', 'Atletico %s'],
  de => ['SV %s', 'SC %s', 'TSV %s', '1. FC %s', 'VfL %s', 'Sportfreunde %s', 'FSV %s', 'Eintracht %s 1910'],
  fr => ['Olympique %s', 'Stade %s', 'AS %s', 'Racing Club %s', 'US %s', 'Football Club %s', 'SC %s'],
  nl => ['SC %s', 'VV %s', '%s Boys', 'FC %s 1920', 'Sportclub %s', 'Quick %s'],
  tr => ['%sspor', '%s FK', '%s Gençlik', '%s Belediye', '%s İdman Yurdu'],
  xx => ['FK %s', 'FC %s', 'Sporting %s', '%s SC', 'Atletik %s', 'Olimpik %s', 'Dinamo %s 1922', 'Lokomotiv %s', 'Spartak %s'],
);
my %usedClub;
sub fake_club {
  my ($c) = @_;
  my $city = city_of($c);
  my $pats = $PAT{ $LANG{$c->{league}} // 'xx' };
  for my $pat (shuffle @$pats) {
    my $n = sprintf $pat, $city;
    next if $usedClub{lc $n} || $realName{lc $n};
    $usedClub{lc $n} = 1; return $n;
  }
  for my $k (2 .. 99) { my $n = sprintf("%s %d", sprintf($pats->[0], $city), 1900 + $k); next if $usedClub{lc $n}++; return $n }
}
# Cidade do clube; sem cidade no Wikidata, usa a de outro clube do mesmo país (nunca o nome real do clube)
my %cities; for my $c (@{ $db->{clubs} }) { push @{ $cities{$c->{league}} }, clean_city($c->{city}) if $c->{city} && clean_city($c->{city}) }
sub clean_city { my $s = shift // return; $s =~ s/\s*\(.*//; $s =~ s/,.*//; $s =~ /^[^\d]{3,30}$/ ? $s : undef }
my %cityOf;
sub city_of { my $c = shift; $cityOf{$c->{id}} //= clean_city($c->{city}) // do { my $l = $cities{$c->{league}} // ['Vila Nova']; $l->[$c->{id} % @$l] } }
sub fake_stadium { my ($c) = @_; my $city = city_of($c);
  my @o = ("Estádio de $city", "Arena $city", "Estádio Municipal de $city", "Estádio Central de $city"); $o[$c->{id} % @o] }

# ---------- saída no formato do jogo ----------
sub pack_data {
  my ($fict) = @_;
  my %seenLg; my @lgs;
  for my $l (@{ $db->{leagues} }) {
    next if $seenLg{$l->{id}}++;
    my $t2 = $lgInfo{"$l->{id}-2"};
    my $r = $PAIS{$l->{id}};
    push @lgs, {id => $l->{id}, country => $l->{country}, conf => $l->{conf},
      name => $fict ? "1ª Divisão ($l->{country})" : $l->{name}, ($t2 ? (name2 => $fict ? "2ª Divisão ($l->{country})" : $t2->{name}, promo => $r ? $r->[0] : 2) : (promo => 0)),
      cup => $r ? ($fict ? $r->[2] : $r->[1]) : "Copa $l->{country}"};
  }
  my @cl = map { my $c = $_;
    {id => $c->{id}, name => $fict ? fake_club($c) : $c->{name}, league => $c->{league}, tier => $c->{tier},
      stadium => $fict || !$c->{stadium} ? fake_stadium($c) : $c->{stadium}, seats => $c->{seats} || 12000,
      players => [map { [$fict ? fake_player($_->{nat}) : $_->{name}, $_->{pos}, $_->{age}, $_->{value}, $_->{nat}] } @{ $byClub{$c->{id}} // [] }]}
  } @{ $db->{clubs} };
  my $names = $fict
    ? {LIB => 'Taça dos Campeões da América', SUL => 'Copa Continental', EU => 'Copa dos Campeões', INT => 'Mundial de Clubes', SMW => 'Super Mundial de Clubes'}
    : {LIB => 'Copa Libertadores', SUL => 'Copa Sul-Americana', EU => 'Copa dos Campeões', INT => 'Mundial de Clubes', SMW => 'Super Mundial de Clubes'};
  {version => $db->{version}, fictional => $fict ? JSON::PP::true : JSON::PP::false, names => $names, leagues => \@lgs, clubs => \@cl};
}
sub write_js {
  my ($file, $var, $data, $head) = @_;
  open my $h, '>:utf8', "$W::ROOT/$file" or die; print $h $head, "window.$var=", JSON::PP->new->canonical->encode($data), ";\n"; close $h;
  printf "%s: %.1f KB\n", $file, (-s "$W::ROOT/$file") / 1024;
}
write_js('data.js', 'GAME_DATA', pack_data(1),
  "// WiFoot Manager — base de dados com nomes fictícios. Forças, idades, posições e capacidades derivadas de dados abertos\n// (Wikipédia CC BY-SA 4.0 e Wikidata CC0); nomes de clubes, jogadores, estádios e competições são inventados. Versão $db->{version}.\n");
write_js('data_real.js', 'GAME_DATA_REAL', pack_data(0),
  "// WiFoot Manager — pacote opcional com nomes reais. Elencos: Wikipédia (CC BY-SA 4.0) e Wikidata (CC0), versão $db->{version}.\n// Força, valor e salário são estimativas do jogo. Distribuição gratuita, separada do aplicativo.\n");
