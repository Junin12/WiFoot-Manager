# Passo 2: elenco principal de cada clube, lido da seção de elenco do artigo do clube na Wikipédia (en).
# Usa só o primeiro bloco {{Fs start}}…{{Fs end}} depois do título do elenco (fora ficam emprestados, base, etc.).
# Saída: db/elencos.json
use strict; use warnings; use utf8; use FindBin; require "$FindBin::Bin/lib.pl";
binmode STDOUT, ':utf8'; $| = 1;

my $ligas = W::load('db/ligas.json');
my @clubs = map { @{ $_->{clubs} } } @$ligas;
my (%out, %wt, %tplOf);
for (my $i = 0; $i < @clubs; $i += 20) {
  my @c = @clubs[$i .. ($i + 19 < $#clubs ? $i + 19 : $#clubs)];
  my $d = W::wiki('en', action => 'query', prop => 'revisions', rvprop => 'content', rvslots => 'main', redirects => 1,
    titles => join('|', map { $_->{title} } @c));
  my %norm = map { $_->{from} => $_->{to} } @{ $d->{query}{normalized} // [] }, @{ $d->{query}{redirects} // [] };
  $wt{$_->{title}} = $_->{revisions}[0]{slots}{main}{content} // '' for @{ $d->{query}{pages} };
  for my $c (@c) {
    my $t = $c->{title}; $t = $norm{$t} while $norm{$t};
    my ($pl, $tpl) = squad($wt{$t} // '');
    $out{$c->{qid}} = {title => $c->{title}, players => $pl};
    $tplOf{$c->{qid}} = $tpl if @$pl < 11 && $tpl;
  }
}
# Elencos em template à parte ({{Clube squad}}, formato Fs2): comum no Chile, Paraguai e outros
my @tq = sort keys %tplOf;
for (my $i = 0; $i < @tq; $i += 20) {
  my @c = @tq[$i .. ($i + 19 < $#tq ? $i + 19 : $#tq)];
  my $d = W::wiki('en', action => 'query', prop => 'revisions', rvprop => 'content', rvslots => 'main', redirects => 1,
    titles => join('|', map { "Template:$tplOf{$_}" } @c));
  my %norm = map { $_->{from} => $_->{to} } @{ $d->{query}{normalized} // [] }, @{ $d->{query}{redirects} // [] };
  my %tw = map { $_->{title} => $_->{revisions}[0]{slots}{main}{content} // '' } @{ $d->{query}{pages} };
  for my $q (@c) {
    my $t = "Template:$tplOf{$q}"; $t = $norm{$t} while $norm{$t};
    my $pl = players_in($tw{$t} // '');
    $out{$q}{players} = $pl if @$pl > @{ $out{$q}{players} };
  }
}
W::save('db/elencos.json', \%out);
my @few = grep { @{ $out{$_->{qid}}{players} } < 15 } @clubs;
printf "%d clubes, %d jogadores; %d clubes com menos de 15 jogadores\n", scalar @clubs, (eval { my $n = 0; $n += @{ $_->{players} } for values %out; $n }), scalar @few;
print "  - $_->{title} (" . scalar(@{ $out{$_->{qid}}{players} }) . ")\n" for @few;

sub squad {
  my $w = shift;
  my $start = 0;
  while ($w =~ /^(=+)\s*([^=\n]+?)\s*\1\s*$/mg) {
    my $h = $2;
    next if $h =~ /loan|youth|academy|reserve|women|under|former|notable|retired|record|captain|history|B team|II\b|management|kit|award|hall|transfer|all-time/i;
    if ($h =~ /squad|players|plantel|roster|current team|first team/i) { $start = pos($w); last }
  }
  my $rest = substr($w, $start);
  my ($tpl) = $rest =~ /\A(?:(?!\n==).)*?\{\{\s*([^{}|\n]+?\bsquad)\s*(?:\||\}\})/is;
  my ($block) = $rest =~ /\{\{\s*(?:fs|football squad)\s*start\b(.*?)\{\{\s*(?:fs|football squad)\s*end\b/is;
  return ([], $tpl) unless defined $block;
  return (players_in($block), $tpl);
}
sub players_in {
  my ($block) = @_;
  my @pl;
  while ($block =~ /\{\{\s*(?:fs2? player|football squad player2?)\s*\|/gi) {
    my $from = pos($block) - length($&);
    my $tpl = balanced($block, $from) // next;
    my %p;
    for my $part (split_top(substr($tpl, 2, -2))) {
      next unless $part =~ /^\s*([a-z]+)\s*=\s*(.*?)\s*$/is;
      $p{lc $1} = $2;
    }
    if (!$p{name} && $p{last}) { # Fs2: first/last/link
      my $n = join ' ', grep { $_ } $p{first}, $p{last};
      $p{name} = '[[' . ($p{link} || $n) . "|$n]]";
    }
    next unless $p{name};
    my ($link, $disp) = $p{name} =~ /\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/;
    my $name = $disp // $link // $p{name};
    $name =~ s/\{\{[^{}]*\}\}|<[^>]+>|'''?//g; $name =~ s/^\s+|\s+$//g;
    next unless $name;
    my $nat = $p{nat} // ''; $nat =~ s/\{\{[^{}]*\}\}//g;
    push @pl, {name => $name, link => $link, nat => $nat, pos => uc($p{pos} // ''), no => $p{no} // ''};
  }
  \@pl;
}
sub balanced { my ($s, $i) = @_; my $d = 0;
  for (my $k = $i; $k < length($s) - 1; $k++) {
    my $two = substr($s, $k, 2);
    if ($two eq '{{') { $d++; $k++ } elsif ($two eq '}}') { $d--; $k++; return substr($s, $i, $k - $i + 1) if $d == 0 }
  } undef }
sub split_top { my $s = shift; my ($d, $cur, @p) = (0, '');
  for my $ch (split //, $s) {
    $d++ if $ch eq '{' || $ch eq '['; $d-- if $ch eq '}' || $ch eq ']';
    if ($ch eq '|' && $d == 0) { push @p, $cur; $cur = '' } else { $cur .= $ch }
  } (@p, $cur) }
