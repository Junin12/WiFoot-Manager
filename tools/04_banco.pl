# Passo 4: monta o banco do WiFoot (nomes reais, dados abertos) e estima força, valor e salário.
#
# Modelo de força (próprio do jogo, só com sinais públicos):
#  1. Nível da liga: média dos 11 melhores de um clube mediano e amplitude entre o maior e o menor clube
#     (valores definidos pelo jogo na tabela %NIVEL).
#  2. Posição do clube dentro da liga: pela notoriedade do elenco (artigos na Wikipédia em todas as línguas
#     e jogos pela seleção principal de cada jogador).
#  3. Posição do jogador dentro do elenco pelos mesmos sinais, com ajuste por idade.
#  Valor e salário saem da força e da idade, com as mesmas fórmulas do jogo.
# Saída: db/wifoot-db.json
use strict; use warnings; use utf8; use FindBin; require "$FindBin::Bin/lib.pl";
use POSIX qw(floor); use List::Util qw(sum min max);
binmode STDOUT, ':utf8'; $| = 1;

my $HOJE = '2026-10-09';
# id-divisão => [média dos 11 melhores do clube mediano, amplitude do maior ao menor clube]
my %NIVEL = (
  'GB1-1' => [79.5, 9], 'GB1-2' => [70, 6], 'ES1-1' => [77, 11], 'ES1-2' => [68, 6], 'IT1-1' => [77, 10], 'IT1-2' => [67.5, 6],
  'L1-1' => [77, 10], 'L1-2' => [68, 6], 'FR1-1' => [75.5, 10], 'FR1-2' => [66, 6], 'PO1-1' => [70, 12], 'PO1-2' => [62, 6],
  'NL1-1' => [70, 11], 'NL1-2' => [61, 6], 'BE1-1' => [70, 9], 'BE1-2' => [62, 6], 'TR1-1' => [71, 10], 'TR1-2' => [63, 6],
  'SC1-1' => [66, 12], 'SC1-2' => [58, 6], 'GR1-1' => [67, 10], 'RU1-1' => [69, 9], 'UKR1-1' => [65, 10], 'DK1-1' => [67, 8],
  'AT1-1' => [67, 9], 'CH1-1' => [67, 8], 'SE1-1' => [64, 7], 'NO1-1' => [64.5, 8], 'PL1-1' => [65.5, 8], 'CZ1-1' => [65.5, 9],
  'HR1-1' => [64, 9], 'RS1-1' => [63, 10], 'BR1-1' => [71.5, 8], 'BR1-2' => [64, 6], 'AR1-1' => [68, 8], 'AR1-2' => [61, 6],
  'UY1-1' => [64, 8], 'CO1-1' => [65, 8], 'CL1-1' => [63.5, 8], 'PY1-1' => [63, 8], 'EC1-1' => [64.5, 8], 'PE1-1' => [61.5, 7],
  'BO1-1' => [58, 7], 'VE1-1' => [58.5, 7], 'MX1-1' => [69, 7], 'US1-1' => [68, 7], 'KSA1-1' => [70, 10],
);
my %CONF = map { $_ => 'CONMEBOL' } qw(BR1 AR1 UY1 CO1 CL1 PY1 EC1 PE1 BO1 VE1);
$CONF{$_} = 'OUTRA' for qw(MX1 US1 KSA1);

my $ligas = W::load('db/ligas.json');
my $el = W::load('db/elencos.json');
my $wd = W::load('db/wikidata.json');
my ($P, $T2Q, $CL, $LAB) = @$wd{qw(players title2qid clubs labels)};

# Nacionalidade: código FIFA (BRA) ou nome em inglês -> nome em português
my %natPt;
for my $l (values %$LAB) { next unless $l->{en}; my $pt = $l->{pt} // $l->{en}; $natPt{uc $l->{fifa}} = $pt if $l->{fifa}; $natPt{lc $l->{en}} = $pt }
# Códigos FIFA (Wikidata): ficam nas federações e seleções; o país é o mais frequente entre elas
my %fifaN;
for my $b (@{ W::sparql(q{SELECT ?code ?pt (COUNT(?x) AS ?n) WHERE { ?x wdt:P3441 ?code ; wdt:P17 ?c . ?c rdfs:label ?pt . FILTER(LANG(?pt) = "pt") } GROUP BY ?code ?pt}) }) {
  my ($code, $n) = (uc $b->{code}{value}, $b->{n}{value});
  if (!$fifaN{$code} || $n > $fifaN{$code}) { $fifaN{$code} = $n; $natPt{$code} = $b->{pt}{value} }
}
$natPt{NED} = 'Holanda';
# Códigos usados na Wikipédia fora do padrão FIFA
my %FIFA_EXTRA = (ENG => 'Inglaterra', SCO => 'Escócia', WAL => 'País de Gales', NIR => 'Irlanda do Norte', KOS => 'Kosovo',
  NGR => 'Nigéria', ROM => 'Romênia', SER => 'Sérvia', SLO => 'Eslovênia', SPA => 'Espanha', SWI => 'Suíça', CHE => 'Suíça', JAP => 'Japão',
  LIT => 'Lituânia', LAT => 'Letônia', DRC => 'República Democrática do Congo', SUD => 'Sudão', PRY => 'Paraguai', DNK => 'Dinamarca',
  CAF => 'República Centro-Africana', CAR => 'República Centro-Africana', GLP => 'Guadalupe', GUF => 'Guiana Francesa', CUR => 'Curaçao',
  GBS => 'Guiné-Bissau', MRT => 'Mauritânia', TGO => 'Togo', PHL => 'Filipinas', SGP => 'Singapura', SMA => 'São Martinho', JER => 'Jersey',
  TR => 'Turquia', CRI => 'Costa Rica', NIC => 'Nicarágua', GMB => 'Gâmbia');
sub nat_pt { my $n = shift // ''; $n =~ s/^\s+|\s+$//g; return $FIFA_EXTRA{uc $n} // $natPt{uc $n} // $natPt{lc $n} // $n }

sub age_of { my $b = shift or return undef; my ($y, $m, $d) = split /-/, $b; my ($Y, $M, $D) = split /-/, $HOJE;
  return undef unless $y && $y > 1950; my $a = $Y - $y; $a-- if $m > $M || ($m == $M && $d > $D); $a }
sub age_mult { my $a = shift; $a <= 21 ? 1.6 : $a <= 24 ? 1.3 : $a <= 28 ? 1 : $a <= 30 ? .8 : $a <= 32 ? .55 : .3 }
sub nice { my $v = shift; my $m = $v >= 1e7 ? 1e6 : $v >= 1e6 ? 1e5 : $v >= 1e5 ? 25000 : 5000; max(10000, $m * int($v / $m + .5)) }
sub hash_n { my $s = shift; my $h = 0; $h = ($h * 31 + ord) % 1000003 for split //, $s; $h }
sub pos_of {
  my ($fs, $labels) = @_;
  my $lab = join ' ', @$labels;
  return 'G' if $fs eq 'GK' || (!$fs && $lab =~ /goalkeeper/i);
  if ($fs eq 'DF' || (!$fs && $lab =~ /defender|back/i)) { return $lab =~ /full-back|fullback|wing-back|left back|right back|lateral/i && $lab !~ /centre-back|center-back/i ? 'L' : 'Z' }
  return 'M' if $fs eq 'MF' || (!$fs && $lab =~ /midfield/i);
  return 'A' if $fs eq 'FW' || (!$fs && $lab =~ /forward|striker|winger/i);
  return 'M';
}

# Nome curto do clube a partir do título do artigo: "Manchester United F.C." -> "Manchester United"
sub short_name {
  my $n = shift; $n =~ s/\s*\(.*?\)//g;
  my $orig = $n;
  my $aff = qr/(?:A\.?F\.?C\.?|F\.?C\.?|C\.?F\.?|S\.?C\.?|A\.?C\.?|C\.?R\.?|S\.?E\.?|E\.?C\.?|C\.?A\.?|S\.?S\.?|U\.?S\.?|A\.?S\.?|C\.?D\.?|S\.?V\.?|K\.?|R\.?|FK|SK|NK|PFC|CSD|CD|SD|UD|RCD|CA|Club|Clube|Club Atlético|Clube Atlético|Club Deportivo|Club Social y Deportivo|Futebol Clube|Esporte Clube|Football Club|Club de Fútbol|Calcio|Deportivo)/;
  1 while $n =~ s/^$aff\s+(?=\S{3})// || $n =~ s/(?<=\S{3})\s+$aff$//;
  $n =~ s/^\s+|\s+$//g;
  length($n) >= 3 ? $n : $orig;
}
my (@leagues, @clubs, @players, %pid);
my ($cid, $nid) = (1, 1);
for my $lg (@$ligas) {
  my $key = "$lg->{id}-$lg->{tier}";
  my $niv = $NIVEL{$key} or die "sem nível para $key";
  push @leagues, {id => $lg->{id}, tier => $lg->{tier}, name => $lg->{name}, country => $lg->{country}, conf => $CONF{$lg->{id}} // 'UEFA', source => $lg->{article}};
  my @cs;
  for my $c (@{ $lg->{clubs} }) {
    my $info = $CL->{$c->{qid}} // {};
    my @pl;
    for my $sp (@{ $el->{$c->{qid}}{players} // [] }) {
      my $q = $sp->{link} ? $T2Q->{$sp->{link}} : undef;
      my $w = $q ? $P->{$q} // {} : {};
      my $age = age_of($w->{birth});
      my $raw = 7 * log(1 + ($w->{links} // 0)) + 2 * log(1 + ($w->{caps} // 0));
      push @pl, {qid => $q, name => $sp->{name}, pos => pos_of($sp->{pos}, [map { $LAB->{$_}{en} // '' } @{ $w->{pos} // [] }]),
        age => $age // 21 + hash_n($sp->{name}) % 9, age_est => defined $age ? 0 : 1, birth => $w->{birth},
        nat => nat_pt($sp->{nat} || ($w->{nat} ? $LAB->{$w->{nat}}{en} : '')), height => $w->{height} ? int($w->{height} + .5) : undef, raw => $raw};
    }
    my @top = (sort { $b <=> $a } map { $_->{raw} } @pl)[0 .. min(15, $#pl)];
    my $cRaw = @pl ? sum(@top) / @top : 0;
    my $venue = $info->{venue} ? $LAB->{$info->{venue}} : undef;
    my $city = $info->{city} ? $LAB->{$info->{city}} : undef;
    push @cs, {qid => $c->{qid}, name => short_name($c->{title}), wiki => $c->{title}, league => $lg->{id}, tier => $lg->{tier},
      city => $city ? $city->{pt} // $city->{es} // $city->{en} : undef, stadium => $venue ? $venue->{pt} // $venue->{en} : undef,
      seats => $venue && $venue->{cap} ? int $venue->{cap} : undef, founded => $info->{founded}, raw => $cRaw + .02 * ($info->{links} // 0), pl => \@pl};
  }
  # Nível de cada clube pela posição no ranking de notoriedade da liga
  my @ord = sort { $b->{raw} <=> $a->{raw} } @cs;
  for my $i (0 .. $#ord) {
    my $c = $ord[$i]; my $pc = @ord > 1 ? 1 - $i / $#ord : .5;
    my $lvl = $niv->[0] + $niv->[1] * ($pc - .5);
    my @ps = sort { $b->{raw} <=> $a->{raw} } @{ $c->{pl} };
    for my $k (0 .. $#ps) {
      my $p = $ps[$k];
      my $off = $k < 11 ? 5 - 7 * $k / 10 : -2 - 8 * min(1, ($k - 11) / 14);
      $off -= 1.5;
      $off += 2 if $p->{raw} > $c->{raw} + 8; # destaque muito acima do elenco
      $off -= $p->{age} >= 35 ? 4 : $p->{age} >= 33 ? 2 : 0;
      $off -= 2 if $p->{age} <= 19;
      my $r = max(40, min(93, int($lvl + $off + .5)));
      my $v = nice(1e5 * 10 ** (($r - 48) / 12.5) * age_mult($p->{age}));
      my $id = $p->{qid} && $pid{$p->{qid}} ? undef : $nid++;
      next unless $id; # mesmo jogador listado em dois clubes: fica no primeiro
      $pid{$p->{qid}} = $id if $p->{qid};
      push @players, {id => $id, qid => $p->{qid}, name => $p->{name}, club => $cid, pos => $p->{pos}, age => $p->{age}, age_est => $p->{age_est},
        birth => $p->{birth}, nat => $p->{nat}, height => $p->{height}, force => $r, value => $v, wage => max(1000, 100 * int($v * .0016 / 100 + .5))};
    }
    push @clubs, {id => $cid++, qid => $c->{qid}, name => $c->{name}, wiki => $c->{wiki}, league => $c->{league}, tier => $c->{tier},
      city => $c->{city}, stadium => $c->{stadium}, seats => $c->{seats}, founded => $c->{founded}, level => sprintf('%.1f', $lvl) + 0};
  }
}
W::save('db/wifoot-db.json', {
  version => $HOJE,
  license => 'Dados de elencos e clubes: Wikipédia (CC BY-SA 4.0) e Wikidata (CC0). Força, valor e salário: estimativas do WiFoot Manager.',
  sources => ['https://en.wikipedia.org (artigos das temporadas e dos clubes)', 'https://www.wikidata.org'],
  leagues => \@leagues, clubs => \@clubs, players => \@players});
printf "ligas: %d · clubes: %d · jogadores: %d (idade estimada: %d)\n", scalar @leagues, scalar @clubs, scalar @players, scalar grep { $_->{age_est} } @players;
