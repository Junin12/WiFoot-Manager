# Passo 3b: as duas cores de cada clube (cor não é marca; o jogo só desenha um escudo genérico com elas).
# Fonte 1: cores oficiais no Wikidata (P6364, CC0). Fonte 2: uniforme 1 na caixa de informações da Wikipédia
# em inglês (camisa body1 e calção shorts1). Saída: db/cores.json  {qid: ["#rrggbb", "#rrggbb"]}
use strict; use warnings; use utf8; use FindBin; require "$FindBin::Bin/lib.pl";
binmode STDOUT, ':utf8'; $| = 1;

my $ligas = W::load('db/ligas.json');
my @clubs = map { @{ $_->{clubs} } } @$ligas;

# Wikidata: cores oficiais -> hexadecimal (P465 do item da cor)
my $ce = W::entities([map { $_->{qid} } @clubs], 'claims|sitelinks|labels');
my %wd; my %colq;
for my $c (@clubs) {
  my @q = map { $_->{mainsnak}{datavalue}{value}{id} // () } @{ $ce->{$c->{qid}}{claims}{P6364} // [] };
  $wd{$c->{qid}} = \@q; $colq{$_} = 1 for @q;
}
my $cole = W::entities([sort keys %colq], 'claims');
my %hex = map { my ($h) = map { $_->{mainsnak}{datavalue}{value} // () } @{ $cole->{$_}{claims}{P465} // [] }; $h ? ($_ => '#' . lc $h) : () } keys %colq;

# Wikipédia: cores do uniforme 1
my %kit; my @t = map { $_->{title} } @clubs;
for (my $i = 0; $i < @t; $i += 50) {
  my @c = @t[$i .. ($i + 49 < $#t ? $i + 49 : $#t)];
  my $d = W::wiki('en', action => 'query', prop => 'revisions', rvprop => 'content', rvslots => 'main', redirects => 1, titles => join('|', @c));
  my %to = map { $_->{from} => $_->{to} } @{ $d->{query}{normalized} // [] }, @{ $d->{query}{redirects} // [] };
  my %txt = map { $_->{title} => $_->{revisions}[0]{slots}{main}{content} // '' } @{ $d->{query}{pages} };
  for my $title (@c) {
    my $x = $title; $x = $to{$x} while $to{$x};
    my $s = $txt{$x} // next;
    $kit{$title} = [map { my ($h) = $s =~ /\|\s*$_\s*=\s*#?([0-9A-Fa-f]{6})\b/; $h ? '#' . lc $h : () } qw(body1 shorts1 socks1)];
  }
}

sub rgb { my $h = shift; map { hex } $h =~ /#(..)(..)(..)/ }
sub dist { my @a = rgb($_[0]), my @b = rgb($_[1]); sqrt(($a[0] - $b[0])**2 + ($a[1] - $b[1])**2 + ($a[2] - $b[2])**2) }
sub lum { my @c = rgb(shift); .299 * $c[0] + .587 * $c[1] + .114 * $c[2] }
my (%out, %src);
for my $c (@clubs) {
  my @w = map { $hex{$_} // () } @{ $wd{$c->{qid}} };
  my @k = @{ $kit{$c->{title}} // [] };
  my @cand = @w >= 2 ? @w : (@w, @k);
  my $c1 = $cand[0] // next;
  my ($c2) = grep { dist($c1, $_) > 90 } @cand[1 .. $#cand];
  $c2 //= lum($c1) > 140 ? '#1a1a1a' : '#ffffff'; # sem segunda cor distinta: contraste
  $out{$c->{qid}} = [$c1, $c2]; $src{@w >= 2 ? 'wikidata' : @k ? 'wikipédia' : 'só uma cor'}++;
}
# Correções manuais: clubes com três cores oficiais em que a dupla automática não é a tradicional
my %FIX = (Q17479 => ["#e2001a", "#000000"], Q221695 => ["#005ca9", "#000000"]); # Flamengo, Grêmio
$out{$_} = $FIX{$_} for grep { $out{$_} } keys %FIX;
W::save('db/cores.json', \%out);
printf "cores: %d de %d clubes (%s)\n", scalar keys %out, scalar @clubs, join(', ', map { "$_ $src{$_}" } sort keys %src);
