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
# Lembram os reais sem repeti-los: clube com o mesmo começo e as mesmas cores (Cruzeiro -> "Cruzense Azul de Belo Horizonte"),
# jogador com as mesmas iniciais e outros nomes reais da mesma nacionalidade (Kaio Jorge -> "Kiko Joabe").
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
sub ini { my $c = substr(shift, 0, 1); $c =~ tr/ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑáàâãäéèêëíìîïóòôõöúùûüçñ/AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn/; uc $c }
# Índice nacionalidade -> tipo (f nome, l sobrenome, m apelido) -> inicial; "*" junta todas as nacionalidades
my %ix;
for my $t ([f => \%first], [l => \%last], [m => \%mono]) {
  my ($k, $h) = @$t;
  for my $nat (sort keys %$h) { for my $w (sort keys %{ $h->{$nat} }) { push @{ $ix{$nat}{$k}{ini($w)} }, $w; push @{ $ix{'*'}{$k}{ini($w)} }, $w } }
}
# Outra palavra da mesma lista e com a mesma inicial (de preferência da mesma nacionalidade)
sub same_ini {
  my ($nat, $k, $w) = @_;
  for my $src ($nat, '*') {
    my @c = grep { lc($_) ne lc($w) && length($_) > 2 } @{ $ix{$src}{$k}{ini($w)} // [] };
    return $c[rand @c] if @c >= ($src eq '*' ? 1 : 3);
  }
  return;
}
my %usedName;
sub fake_player {
  my ($nat, $real) = @_;
  my @w = split /\s+/, $real;
  for (1 .. 40) {
    my $n;
    if (@w == 1) { $n = same_ini($nat, 'm', $w[0]) // same_ini($nat, 'f', $w[0]) }
    else { my ($f, $l) = (same_ini($nat, 'f', $w[0]), same_ini($nat, 'l', $w[-1])); $n = "$f $l" if $f && $l }
    next if !$n || $realName{lc $n} || $usedName{$n}++;
    return $n;
  }
  # Sem combinação inédita: aceita repetir (apelidos se repetem no futebol)
  return same_ini($nat, 'm', $w[0]) // same_ini($nat, 'f', $w[0]) // $w[0] . 'son' if @w == 1;
  join ' ', same_ini($nat, 'f', $w[0]) // $w[0], same_ini($nat, 'l', $w[-1]) // $w[-1] . 's';
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
# Finais que trocam o resto da palavra (Cruzeiro -> Cruz + ense)
my %END = (
  pt => [qw(ense ista ano ino al ária ório ão)], es => [qw(ense ino ano eño al era ales ía)],
  en => [qw(ford ton field wick by dale ham worth bury ley)], it => [qw(ese ino etta ana ello ona ica)],
  de => [qw(burg heim stein dorf au berg feld hausen)], fr => [qw(ais ville ac ennes ois ard ière)],
  nl => [qw(dam hoven wijk um sel horst)], tr => [qw(kent ova gücü lar han tepe)], xx => [qw(ovo ica ar ia ets an ino)],
);
# Palavras genéricas, que ficam como estão (não identificam o clube)
my $GENERIC = qr/^(?:(?-i:[[:upper:]\d.]{1,4})|\d+|&|de|da|do|dos|das|del|di|la|las|los|el|the|of|y|e|and|united|city|town|county|athletic|rovers|wanderers|albion|real|atlético|atletico|club|clube|sporting|sport|deportivo|esporte|futebol|calcio|inter|internacional|racing|olympique|stade|union|unión|união|borussia|eintracht|dynamo|dinamo|fortuna|hellas|virtus|juventud|universidad|universitario|associação|associacao|atlética|regatas|foot|ball|red|bull|vila|nova|são|santa|santo|recreativo|sociedade|esportiva|sportivo|futbol|fútbol|football|fc|ac|sc|cf|club|team|de|al|ad|cd|ud|sd|nacional|independiente|deportes|central|unido|old|north|south|west|east|end|park|queens|b)$/i;
my $VOW = 'aeiouyáàâãéêíóôõúüöä';
sub mutate { # palavra nova com o mesmo começo e outro final (Cruzeiro -> Cruz + ense, Fulham -> Ful + field)
  my ($w, $lang, $seed) = @_;
  return $1 . mutate($2, $lang, $seed) if $w =~ /^(\w{1,3}-)(\w{3,})$/; # Al-Khaleej -> Al-Khalense
  my $e =$END{$lang} // $END{xx};
  my ($pre, $vow, $cons) = $w =~ /^([^$VOW]*)([$VOW]+)([^$VOW]*)/i or return $w . 'ense';
  for my $i (0 .. $#$e) {
    my $end = $e->[($seed + $i) % @$e];
    my $s = $pre . $vow . substr($cons, 0, $end =~ /^[$VOW]/i || length($pre . $vow) < 3 ? 2 : 1);
    my $n = $s . $end;
    next if index(lc $w, lc $n) == 0 || index(lc $n, lc $w) == 0;
    return $n;
  }
  $pre . $vow . $cons . 'ense';
}
# Nome da cor (para clubes de língua portuguesa e espanhola)
sub cname {
  my ($r, $g, $bl) = map { hex } $_[0] =~ /#(..)(..)(..)/;
  my ($mx, $mn) = ((sort { $b <=> $a } $r, $g, $bl)[0], (sort { $a <=> $b } $r, $g, $bl)[0]);
  return $mx > 190 ? 'white' : $mx < 70 ? 'black' : 'grey' if $mx - $mn < 45;
  my $h = $mx == $r ? 60 * (($g - $bl) / ($mx - $mn)) : $mx == $g ? 60 * (2 + ($bl - $r) / ($mx - $mn)) : 60 * (4 + ($r - $g) / ($mx - $mn));
  $h += 360 if $h < 0;
  return 'claret' if ($h < 15 || $h > 330) && $mx < 150;
  $h < 15 || $h >= 330 ? 'red' : $h < 40 ? 'orange' : $h < 70 ? 'yellow' : $h < 170 ? 'green' : $h < 205 ? 'sky' : $h < 265 ? 'blue' : 'purple';
}
my %CW = (
  pt => {red => 'Rubro', blue => 'Azul', green => 'Verde', yellow => 'Amarelo', black => 'Negro', white => 'Branco', sky => 'Celeste', orange => 'Laranja', purple => 'Violeta', claret => 'Grená', grey => 'Prata',
    'black white' => 'Alvinegro', 'black red' => 'Rubro-Negro', 'green white' => 'Alviverde', 'red white' => 'Alvirrubro', 'black green' => 'Verdinegro', 'blue red' => 'Tricolor', 'black blue' => 'Tricolor', 'green red' => 'Tricolor', 'blue white' => 'Azul'},
  es => {red => 'Rojo', blue => 'Azul', green => 'Verde', yellow => 'Amarillo', black => 'Negro', white => 'Blanco', sky => 'Celeste', orange => 'Naranja', purple => 'Violeta', claret => 'Granate', grey => 'Plata',
    'black white' => 'Albinegro', 'black red' => 'Rojinegro', 'green white' => 'Verdiblanco', 'red white' => 'Rojiblanco', 'blue white' => 'Azul', 'blue red' => 'Azulgrana', 'sky white' => 'Celeste'},
);
sub color_word { my ($c, $lang) = @_; my $col = $c->{colors} or return;
  my @n = map { cname($_) } @$col; $CW{$lang}{join ' ', sort @n} // $CW{$lang}{$n[0]} }
my %usedClub;
sub fake_club {
  my ($c) = @_;
  my $lang = $LANG{$c->{league}} // 'xx';
  my ($seed, $city) = ($c->{id}, city_of($c));
  my @w = split /\s+/, $c->{name};
  my @dist = grep { $_ !~ $GENERIC } @w;
  my @opts;
  if (@dist) {
    my $m = mutate($dist[0], $lang, $seed);
    my @keep = map { $_ eq $dist[0] ? $m : $_ } grep { $_ eq $dist[0] || $_ =~ $GENERIC } @w;
    my $only = (grep { $_ !~ /^(?:[[:upper:]]{2,4}|\d+)$/ } @keep) == 1 ? $m : undef; # siglas (FR, FBPA) não contam
    if ($only && $CW{$lang}) {
      my $k = color_word($c, $lang);
      push @opts, "$only $k de $city" if $k && length("$only $k de $city") <= 32;
      push @opts, "$only $k" if $k;
    }
    push @opts, sprintf($PAT{$lang}[$seed % @{ $PAT{$lang} }], $only) if $only;
    push @opts, join ' ', @keep;
  }
  push @opts, map { sprintf $_, $city } shuffle @{ $PAT{$lang} };
  for my $n (@opts) { next if $usedClub{lc $n} || $realName{lc $n}; $usedClub{lc $n} = 1; return $n }
  for my $k (2 .. 99) { my $n = "$opts[0] " . (1900 + $k); next if $usedClub{lc $n}++; return $n }
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
      stadium => $fict || !$c->{stadium} ? fake_stadium($c) : $c->{stadium}, seats => $c->{seats} || 12000, ($c->{colors} ? (colors => $c->{colors}) : ()),
      players => [map { [$fict ? fake_player($_->{nat}, $_->{name}) : $_->{name}, $_->{pos}, $_->{age}, $_->{value}, $_->{nat}] } @{ $byClub{$c->{id}} // [] }]}
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
