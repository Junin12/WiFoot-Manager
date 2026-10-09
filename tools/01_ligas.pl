# Passo 1: clubes de cada liga na temporada atual, a partir do artigo da temporada na Wikipédia (en).
# Saída: db/ligas.json
use strict; use warnings; use utf8; use FindBin; require "$FindBin::Bin/lib.pl";
binmode STDOUT, ':utf8'; $| = 1;

# [id, divisão, país, nome da liga, artigos candidatos da temporada]
my @L = (
  ['GB1', 1, 'Inglaterra', 'Premier League', '2026–27 Premier League'],
  ['GB1', 2, 'Inglaterra', 'Championship', '2026–27 EFL Championship'],
  ['ES1', 1, 'Espanha', 'LaLiga', '2026–27 La Liga'],
  ['ES1', 2, 'Espanha', 'Segunda División', '2026–27 Segunda División'],
  ['IT1', 1, 'Itália', 'Serie A', '2026–27 Serie A'],
  ['IT1', 2, 'Itália', 'Serie B', '2026–27 Serie B'],
  ['L1', 1, 'Alemanha', 'Bundesliga', '2026–27 Bundesliga'],
  ['L1', 2, 'Alemanha', '2. Bundesliga', '2026–27 2. Bundesliga'],
  ['FR1', 1, 'França', 'Ligue 1', '2026–27 Ligue 1'],
  ['FR1', 2, 'França', 'Ligue 2', '2026–27 Ligue 2'],
  ['PO1', 1, 'Portugal', 'Liga Portugal', '2026–27 Primeira Liga'],
  ['PO1', 2, 'Portugal', 'Liga Portugal 2', '2026–27 Liga Portugal 2'],
  ['NL1', 1, 'Holanda', 'Eredivisie', '2026–27 Eredivisie'],
  ['NL1', 2, 'Holanda', 'Eerste Divisie', '2026–27 Eerste Divisie'],
  ['BE1', 1, 'Bélgica', 'Pro League', '2026–27 Belgian Pro League'],
  ['BE1', 2, 'Bélgica', 'Challenger Pro League', '2026–27 Challenger Pro League'],
  ['TR1', 1, 'Turquia', 'Süper Lig', '2026–27 Süper Lig'],
  ['TR1', 2, 'Turquia', '1. Lig', '2026–27 TFF 1. Lig'],
  ['SC1', 1, 'Escócia', 'Premiership', '2026–27 Scottish Premiership'],
  ['SC1', 2, 'Escócia', 'Championship', '2026–27 Scottish Championship'],
  ['GR1', 1, 'Grécia', 'Super League', '2026–27 Super League Greece'],
  ['RU1', 1, 'Rússia', 'Premier Liga', '2026–27 Russian Premier League'],
  ['UKR1', 1, 'Ucrânia', 'Premier Liga', '2026–27 Ukrainian Premier League'],
  ['DK1', 1, 'Dinamarca', 'Superliga', '2026–27 Danish Superliga'],
  ['AT1', 1, 'Áustria', 'Bundesliga', '2026–27 Austrian Football Bundesliga'],
  ['CH1', 1, 'Suíça', 'Super League', '2026–27 Swiss Super League'],
  ['SE1', 1, 'Suécia', 'Allsvenskan', '2026 Allsvenskan'],
  ['NO1', 1, 'Noruega', 'Eliteserien', '2026 Eliteserien'],
  ['PL1', 1, 'Polônia', 'Ekstraklasa', '2026–27 Ekstraklasa'],
  ['CZ1', 1, 'República Tcheca', 'Liga Tcheca', '2026–27 Czech First League'],
  ['HR1', 1, 'Croácia', 'HNL', '2026–27 Croatian Football League|2026–27 SuperSport HNL'],
  ['RS1', 1, 'Sérvia', 'SuperLiga', '2026–27 Serbian SuperLiga'],
  ['BR1', 1, 'Brasil', 'Brasileirão Série A', '2026 Campeonato Brasileiro Série A'],
  ['BR1', 2, 'Brasil', 'Brasileirão Série B', '2026 Campeonato Brasileiro Série B'],
  ['AR1', 1, 'Argentina', 'Liga Profesional', '2026 Argentine Primera División'],
  ['AR1', 2, 'Argentina', 'Primera Nacional', '2026 Primera Nacional'],
  ['UY1', 1, 'Uruguai', 'Primera División', '2026 Liga AUF Uruguaya|2026 Liga AUF Uruguaya season|2026 Uruguayan Primera División season|Liga AUF Uruguaya'],
  ['CO1', 1, 'Colômbia', 'Primera A', '2026 Categoría Primera A season|2026 Categoría Primera A'],
  ['CL1', 1, 'Chile', 'Primera División', '2026 Chilean Primera División season|2026 Chilean Primera División|2026 Liga de Primera'],
  ['PY1', 1, 'Paraguai', 'Primera División', '2026 Copa de Primera|2026 Paraguayan Primera División season'],
  ['EC1', 1, 'Equador', 'LigaPro Serie A', '2026 Ecuadorian Serie A|2026 LigaPro Serie A'],
  ['PE1', 1, 'Peru', 'Liga 1', '2026 Liga 1 (Peru)|2026 Peruvian Primera División'],
  ['BO1', 1, 'Bolívia', 'División Profesional', '2026 FBF División Profesional|2026 Bolivian Primera División season'],
  ['VE1', 1, 'Venezuela', 'Liga FUTVE', '2026 Venezuelan Primera División season|2026 Liga FUTVE|2026 Venezuelan Primera División'],
  ['MX1', 1, 'México', 'Liga MX', '2026–27 Liga MX season|2026–27 Liga MX'],
  ['US1', 1, 'Estados Unidos', 'MLS', '2026 Major League Soccer season'],
  ['KSA1', 1, 'Arábia Saudita', 'Saudi Pro League', '2026–27 Saudi Pro League'],
);
# Seções que listam os participantes, em ordem de preferência
my @SEC = (qr/^(League table|Standings|Aggregate table|Table|Overall table|Classification)$/i,
  qr/^(Stadi(ums|a) and locations|Teams and locations|Club information|Clubs|Venues|Participating (teams|clubs)|Personnel and (kits|sponsor(ing|ship)))$/i);
my %CLUBTYPE = map { $_ => 1 } qw(Q476028 Q847017 Q15944511 Q2367225 Q1194951 Q103229495);

my @out;
for my $l (@L) {
  my ($id, $tier, $country, $name, $cands) = @$l;
  my $article;
  for my $t (split /\|/, $cands) {
    my ($pg) = @{ W::wiki('en', action => 'query', titles => $t, redirects => 1)->{query}{pages} };
    if (!$pg->{missing}) { $article = $pg->{title}; last }
  }
  unless ($article) { print "!! $id-$tier: artigo não encontrado ($cands)\n"; next }
  my $secs = W::wiki('en', action => 'parse', page => $article, prop => 'sections')->{parse}{sections};
  # Participantes: união das tabelas de classificação (ligas em zonas têm várias); se vierem incompletas,
  # completa com a seção de estádios/clubes
  my (%std, $loc, $locName);
  for my $k (0 .. $#SEC) {
    for my $s (grep { $_->{line} =~ $SEC[$k] } @$secs) {
      my $links = W::wiki('en', action => 'parse', page => $article, section => $s->{index}, prop => 'links')->{parse}{links};
      my $c = clubs_of([map { $_->{title} } grep { $_->{ns} == 0 && $_->{exists} } @$links]);
      next if @$c > 40;
      if ($k == 0) { $std{$_->{qid}} //= $_ for @$c }
      elsif (!$loc || @$c > @$loc) { ($loc, $locName) = ($c, $s->{line}) }
    }
  }
  my @std = values %std; my ($clubs, $best);
  if (@std >= 8 && (!$loc || @std >= .9 * @$loc)) { ($clubs, $best) = ([sort { $a->{title} cmp $b->{title} } @std], [0, 'classificação']) }
  elsif ($loc && @$loc >= 8) { my %u = map { $_->{qid} => $_ } @$loc, @std; ($clubs, $best) = ([sort { $a->{title} cmp $b->{title} } values %u], [0, "$locName + classificação"]) }
  print sprintf("%-5s %d %-38s %2d clubes (seção %s)
", $id, $tier, $article, scalar @$clubs, $best->[1]) if $clubs;
  unless ($clubs) { print "!! $id-$tier: clubes não encontrados em $article\n"; next }
  push @out, {id => $id, tier => $tier, country => $country, name => $name, article => $article, clubs => $clubs};
}
W::save('db/ligas.json', \@out);

# Títulos de artigos -> clubes de futebol (pelo tipo no Wikidata)
sub clubs_of {
  my ($titles) = @_; my (%qid, @res);
  for (my $i = 0; $i < @$titles; $i += 50) {
    my @c = @$titles[$i .. ($i + 49 < $#$titles ? $i + 49 : $#$titles)];
    my $d = W::wiki('en', action => 'query', prop => 'pageprops', ppprop => 'wikibase_item', redirects => 1, titles => join('|', @c));
    $qid{$_->{title}} = $_->{pageprops}{wikibase_item} for grep { $_->{pageprops} } @{ $d->{query}{pages} };
  }
  my $ents = W::entities([sort values %qid], 'claims|labels');
  my %seen;
  for my $t (@$titles) {
    my $q = $qid{$t} // next; next if $seen{$q}++;
    my $e = $ents->{$q} or next;
    my @types = map { $_->{mainsnak}{datavalue}{value}{id} // () } @{ $e->{claims}{P31} // [] };
    next unless grep { $CLUBTYPE{$_} } @types;
    next if grep { $_ eq 'Q1478437' || $_ eq 'Q6979593' } @types; # seleção nacional
    push @res, {qid => $q, title => $t};
  }
  \@res;
}
