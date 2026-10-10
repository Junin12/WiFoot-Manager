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
# Só a primeira letra lembra o real: clube e cada parte do nome do jogador começam com a mesma letra,
# mas já a segunda letra é diferente (Kaio Jorge -> "Kevin Jaime"). Nada de cidade ou cor no nome do clube.
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
sub ini { norm_ascii(uc substr(shift, 0, 1)) }
# Letras com acento ou de outros alfabetos latinos contam como a letra base (Ł = L, Đ = D, Þ = T)
sub norm_ascii { my $s = shift;
  $s =~ tr/ÁÀÂÃÄÅÆÉÈÊËĘĚÍÌÎÏİÓÒÔÕÖØŌŐÚÙÛÜŪŰŮÇČĆÑŃŇĐĎŁĽĹŠŚŞŽŹŻŘŔŤŢÞĞÝŸ/AAAAAAAEEEEEEIIIIIOOOOOOOOUUUUUUUCCCNNNDDLLLSSSZZZRRTTTGYY/;
  $s =~ tr/áàâãäåæéèêëęěíìîïıóòôõöøōőúùûüūűůçčćñńňđďłľĺšśşžźżřŕťţþğýÿ/aaaaaaaeeeeeeiiiiioooooooouuuuuuucccnnnddlllssszzzrrtttgyy/; $s }
sub norm { norm_ascii(lc shift) }
# Parecido demais? Só a primeira letra pode coincidir, e uma palavra não pode conter a outra
sub far { my ($x, $y) = map { norm($_) } @_; substr($x, 0, 2) ne substr($y, 0, 2) && index($x, $y) < 0 && index($y, $x) < 0 }
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
    my @c = grep { length($_) > 2 && far($_, $w) } @{ $ix{$src}{$k}{ini($w)} // [] };
    return $c[rand @c] if @c >= ($src eq '*' ? 1 : 3);
  }
  return;
}
sub any_ini { my $w = shift; my @c = grep { far($_, $w) } map { @{ $ix{'*'}{$_}{ini($w)} // [] } } qw(l f m); @c ? $c[rand @c] : 'Silva' }
my %usedName;
sub fake_player {
  my ($nat, $real) = @_;
  my @w = split /\s+/, $real;
  # Apelido (uma palavra) vira um primeiro nome comum; nunca o nome de um jogador real
  my $one = sub { for (1 .. 30) { my $n = same_ini($nat, 'f', $w[0]) // any_ini($w[0]); return $n if $n && !$realName{lc $n} } return };
  for (1 .. 40) {
    my $n;
    if (@w == 1) { $n = $one->() }
    else { my ($f, $l) = (same_ini($nat, 'f', $w[0]), same_ini($nat, 'l', $w[-1])); $n = "$f $l" if $f && $l }
    next if !$n || $realName{lc $n} || $usedName{$n}++;
    return $n;
  }
  # Sem combinação inédita: aceita repetir, mas nunca um nome real
  for (1 .. 40) {
    my $n = @w == 1 ? $one->() : join ' ', same_ini($nat, 'f', $w[0]) // any_ini($w[0]), same_ini($nat, 'l', $w[-1]) // any_ini($w[-1]);
    return $n if $n && !$realName{lc $n};
  }
  return any_ini($w[0]) . ' ' . any_ini($w[0]) . 's';
}

my %LANG = (BR1 => 'pt', PO1 => 'pt', GB1 => 'en', SC1 => 'en', US1 => 'en', IT1 => 'it', L1 => 'de', AT1 => 'de', CH1 => 'de',
  FR1 => 'fr', BE1 => 'fr', NL1 => 'nl', TR1 => 'tr', map { $_ => 'es' } qw(ES1 AR1 UY1 CO1 CL1 PY1 EC1 PE1 BO1 VE1 MX1));
# Modelos de nome em que a palavra principal vem primeiro (o nome começa com a mesma letra do real)
my %PAT = (
  pt => ['%s Futebol Clube', '%s Esporte Clube', '%s FC', '%s Atlético Clube', '%s Sport Club', '%s EC', '%s'],
  es => ['%s Fútbol Club', '%s FC', '%s Club de Fútbol', '%s Deportivo', '%s Atlético', '%s Sporting Club', '%s'],
  en => ['%s Athletic', '%s Rovers', '%s Town', '%s Wanderers', '%s Albion', '%s FC', '%s'],
  it => ['%s Calcio', '%s FC', '%s Sportiva', '%s 1910', '%s Football Club', '%s'],
  de => ['%s SV', '%s FC', '%s SC 1907', '%s Sportfreunde', '%s 04', '%s'],
  fr => ['%s FC', '%s Football Club', '%s Athlétique', '%s Sport', '%s'],
  nl => ['%s Boys', '%s FC', '%s Voetbalclub', '%s SC', '%s'],
  tr => ['%sspor', '%s FK', '%s Gençlik', '%s Belediyespor', '%s'],
  xx => ['%s FC', '%s FK', '%s SC', '%s Sport', '%s'],
);
# Palavras típicas de nomes de clubes (português e espanhol); as que já são clubes do banco ficam de fora
my %WORDS = (
  pt => [qw(Alvorada Aliança Andorinha Araguaia Atalaia Avante Bandeirante Baluarte Bonança Borboleta Brisa Cometa Comercial Colonial Caravela
    Cachoeira Centauro Diamante Dourado Democrata Desportiva Estrela Esperança Expresso Eldorado Esmeralda Ferroviário Fênix Farol Fronteira
    Guarany Gaivota Girassol Gavião Horizonte Harmonia Humaitá Ipiranga Imperial Itapuã Ibirapuera Jaguar Jequitibá Jangada Kaeté Kayapó
    Lusitano Luzeiro Lagoa Mercantil Maravilha Marajó Monteverde Norte Noroeste Operário Olaria Oriente Progresso Paraíso Pioneiro Primavera
    Planalto Quilombo Riachuelo Relâmpago Ribeira Serrano Sertão Sabiá Seleto Tupi Trovão Tamoio Tropical Uirapuru Universal Ubirajara
    Ventania Vitorioso Vale Viking Xavante Ypê Yaguara Zênite Zumbi
    Acauã Altamira Arapuã Anhanguera Aymoré Bambuí Barroca Boiadeiro Bandeira Canarinho Cerrado Coqueiral Candango Capivari Cabanos
    Floresta Ferrugem Formosa Fortim Goitacá Guanabara Graúna Guará Missões Mangueira Mocambo Moinho Paineiras Pantanal Pajuçara Potiguar
    Recreio Retiro Rondon Rubi Saturno Sentinela Solimões Sereia Sobradinho Sucuri Vanguarda Veloz Vencedor Vertente Encantado Estância
    Tabajara Taquari Timbira Tupinambá Tapajós Iguaçu Itaúna Iracema Oásis Navegantes Nordeste Liberdade Laranjeiras Litoral)],
  es => [qw(Alborada Amanecer Andino Bravío Bonanza Cóndor Centella Cumbre Dorado Defensa Estrella Esperanza Fénix Fortín Gaviota Guerreros
    Halcón Imperio Iguazú Jaguares Lucero Montaña Mirador Norteño Oriental Pampa Porvenir Quetzal Relámpago Serranos Tormenta Trueno
    Volcán Valle Yaguareté Zonda Ombú Kollas Ñandú Pucará Urquiza Wanka
    Arrieros Barrancas Cardenales Centauros Corsarios Diablos Escorpiones Gauchos Gladiadores Leones Llaneros Marinos Milagro Piratas
    Patriotas Ribereños Saeta Sabaneros Salinas Tiburones Toros Titanes Vencedores Vikingos Nogales Olimpo Albatros Bucaneros Cometas)],
);
my %NATLANG = ((map { $_ => 'pt' } 'Brasil', 'Portugal'),
  (map { $_ => 'es' } 'Argentina', 'Espanha', 'Colômbia', 'Uruguai', 'Venezuela', 'Equador', 'Paraguai', 'México', 'Bolívia', 'Peru', 'Chile'));
# Sobrenomes por nacionalidade (um clube grego ganha um sobrenome grego, e assim por diante), por inicial
my %sur;
for my $p (@{ $db->{players} }) {
  my @w = split /\s+/, $p->{name}; next if @w < 2;
  my $s = $w[-1]; next unless $s =~ /^\p{Lu}\p{Ll}{3,9}$/;
  $sur{$p->{nat}}{ini($s)}{$s} = 1; $sur{'*'}{ini($s)}{$s} = 1;
}
for my $n (values %sur) { $_ = [sort keys %$_] for values %$n }
my %realTok = map { (lc(norm($_)) => 1) } map { split /\s+/, $_->{name} } @{ $db->{clubs} };
my %lgCountry = map { $_->{id} => $_->{country} } @{ $db->{leagues} };
my (%usedClub, %usedWord);
sub fake_club {
  my ($c) = @_;
  my $lang = $LANG{$c->{league}} // 'xx';
  my $country = $lgCountry{$c->{league}} // '';
  my ($first) = grep { /^\p{L}{2}/ } split /\s+/, $c->{name}; $first //= $c->{name};
  my $pats = $PAT{$lang}; my @full = grep { $_ ne '%s' } @$pats; # sobrenome sozinho não parece clube
  my $wl = $WORDS{$NATLANG{$country} // ''} // [];
  for my $src ([[grep { ini($_) eq ini($first) } @$wl], $pats], [$sur{$country}{ini($first)}, \@full], [$sur{'*'}{ini($first)}, \@full]) {
    my ($list, $pp) = @$src;
    for my $w (shuffle grep { !$usedWord{$_} && !$realTok{lc norm($_)} && far($_, $first) } @{ $list // [] }) {
      my $n = sprintf $pp->[rand @$pp], $w;
      next if $usedClub{lc $n} || $realName{lc $n};
      $usedClub{lc $n} = $usedWord{$w} = 1; return $n;
    }
  }
  my $n = sprintf $full[0], city_of($c); $n .= ' ' . (1900 + $c->{id} % 100) while $usedClub{lc $n}++; $n;
}
# Cores da versão comercial: a principal é a do clube; a segunda é sorteada entre cores que contrastam com ela
my @PALETA = ('#ffffff', '#111111', '#0b2a6b', '#c8102e', '#f2c400', '#0a7d3b', '#5bb4e5', '#f07800', '#5b2a86', '#7a1f2b', '#8e9aa6', '#e8e1c5');
sub cdist { my @a = map { hex } $_[0] =~ /#(..)(..)(..)/; my @b = map { hex } $_[1] =~ /#(..)(..)(..)/;
  sqrt(($a[0] - $b[0])**2 + ($a[1] - $b[1])**2 + ($a[2] - $b[2])**2) }
sub fake_colors { my $c1 = shift->[0]; my @ok = grep { cdist($c1, $_) > 160 } @PALETA; [$c1, $ok[rand @ok]] }
# Cidade do clube; sem cidade no Wikidata, usa a de outro clube do mesmo país (nunca o nome real do clube)
my %cities; for my $c (@{ $db->{clubs} }) { push @{ $cities{$c->{league}} }, clean_city($c->{city}) if $c->{city} && clean_city($c->{city}) }
sub clean_city { my $s = shift // return; $s =~ s/\s*\(.*//; $s =~ s/,.*//; $s =~ /^[^\d]{3,30}$/ ? $s : undef }
my %cityOf;
sub city_of { my $c = shift; $cityOf{$c->{id}} //= clean_city($c->{city}) // do { my $l = $cities{$c->{league}} // ['Vila Nova']; $l->[$c->{id} % @$l] } }
sub fake_stadium { my ($c) = @_; my $city = city_of($c);
  my @o = ("Estádio de $city", "Arena $city", "Estádio Municipal de $city", "Estádio Central de $city"); $o[$c->{id} % @o] }

# Nome das ligas na versão comercial: "Brasil 1 - Campeonato Brasileiro 1ª Divisão"
my %ADJ = (Inglaterra => 'Inglês', Espanha => 'Espanhol', 'Itália' => 'Italiano', Alemanha => 'Alemão', 'França' => 'Francês', Portugal => 'Português',
  Holanda => 'Holandês', 'Bélgica' => 'Belga', Turquia => 'Turco', 'Escócia' => 'Escocês', 'Grécia' => 'Grego', 'Rússia' => 'Russo', 'Ucrânia' => 'Ucraniano',
  Dinamarca => 'Dinamarquês', 'Áustria' => 'Austríaco', 'Suíça' => 'Suíço', 'Suécia' => 'Sueco', Noruega => 'Norueguês', 'Polônia' => 'Polonês',
  'República Tcheca' => 'Tcheco', 'Croácia' => 'Croata', 'Sérvia' => 'Sérvio', Brasil => 'Brasileiro', Argentina => 'Argentino', Uruguai => 'Uruguaio',
  'Colômbia' => 'Colombiano', Chile => 'Chileno', Paraguai => 'Paraguaio', Equador => 'Equatoriano', Peru => 'Peruano', 'Bolívia' => 'Boliviano',
  Venezuela => 'Venezuelano', 'México' => 'Mexicano', 'Estados Unidos' => 'Estadunidense', 'Arábia Saudita' => 'Saudita');
sub lg_name { my ($country, $n) = @_; "$country $n - Campeonato " . ($ADJ{$country} // "de $country") . " ${n}ª Divisão" }

# ---------- saída no formato do jogo ----------
sub pack_data {
  my ($fict) = @_;
  my %seenLg; my @lgs;
  for my $l (@{ $db->{leagues} }) {
    next if $seenLg{$l->{id}}++;
    my $t2 = $lgInfo{"$l->{id}-2"};
    my $r = $PAIS{$l->{id}};
    push @lgs, {id => $l->{id}, country => $l->{country}, conf => $l->{conf},
      name => lg_name($l->{country}, 1), ($t2 ? (name2 => lg_name($l->{country}, 2), promo => $r ? $r->[0] : 2) : (promo => 0)),
      cup => "Copa Nacional ($l->{country})"};
  }
  my @cl = map { my $c = $_;
    {id => $c->{id}, name => $fict ? fake_club($c) : $c->{name}, league => $c->{league}, tier => $c->{tier}, city => city_of($c),
      stadium => $fict || !$c->{stadium} ? fake_stadium($c) : $c->{stadium}, seats => $c->{seats} || 12000, ($c->{colors} ? (colors => $fict ? fake_colors($c->{colors}) : $c->{colors}) : ()),
      players => [map { [$fict ? fake_player($_->{nat}, $_->{name}) : $_->{name}, $_->{pos}, $_->{age}, $_->{value}, $_->{nat}] } @{ $byClub{$c->{id}} // [] }]}
  } @{ $db->{clubs} };
  # Competições com nomes neutros nas duas versões
  my $names = {LIB => 'América 1', SUL => 'América 2', EU => 'Europa 1', INT => 'Mundial', SMW => 'Mega Mundial'};
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
