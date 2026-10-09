# Funções comuns das ferramentas de coleta (Wikipédia e Wikidata, dados abertos).
# Cada resposta fica em db/cache para que a coleta possa ser refeita sem repetir requisições.
package W;
use strict; use warnings; use utf8;
use JSON::PP; use Digest::MD5 qw(md5_hex); use URI::Escape qw(uri_escape_utf8);
use File::Basename qw(dirname); use Cwd qw(abs_path);

our $ROOT = abs_path(dirname(__FILE__) . '/..');
our $CACHE = "$ROOT/db/cache";
# Política da Wikimedia: identificar a ferramenta com um contato
our $UA = 'WiFootDataBuilder/1.0 (https://github.com/Junin12/WiFoot-Manager)';
our $JSON = JSON::PP->new->utf8->canonical;
my $last = 0;

sub get {
  my ($url, %o) = @_;
  my $key = md5_hex($url . ($o{post} // ''));
  my $f = "$CACHE/" . substr($key, 0, 2) . "/$key.json";
  if (-s $f && !$o{fresh}) { open my $h, '<:raw', $f or die; local $/; return <$h>; }
  mkdir "$CACHE/" . substr($key, 0, 2);
  for my $try (1 .. 5) {
    my $wait = 1.1 - (time - $last); sleep 1 if $wait > 0; $last = time;
    my @cmd = ('curl', '-s', '--compressed', '-m', '90', '-A', $UA, '-w', '\n%{http_code}');
    push @cmd, '-H', 'Accept: application/sparql-results+json', '--data-urlencode', "query=$o{post}" if defined $o{post};
    open my $p, '-|', @cmd, $url or die "curl: $!";
    binmode $p; local $/; my $out = <$p>; close $p;
    my ($body, $code) = $out =~ /\A(.*)\n(\d{3})\z/s or do { sleep 5 * $try; next };
    if ($code == 200) { open my $h, '>:raw', $f or die; print $h $body; close $h; return $body; }
    warn "HTTP $code em $url (tentativa $try)\n"; sleep 10 * $try;
  }
  die "falhou: $url\n";
}
sub getj { # resposta vazia ou cortada: busca de novo sem cache
  my ($url, %o) = @_;
  for my $t (0 .. 3) { my $d = eval { $JSON->decode(get($url, %o, fresh => $t > 0)) }; return $d if $d; sleep 3 * $t }
  die "JSON inválido de $url
";
}
sub esc { uri_escape_utf8($_[0]) }
sub wiki { my ($lang, %p) = @_; getj("https://$lang.wikipedia.org/w/api.php?format=json&formatversion=2&" . join('&', map { "$_=" . esc($p{$_}) } sort keys %p)) }
sub sparql { getj('https://query.wikidata.org/sparql', post => $_[0])->{results}{bindings} }
sub entities { # até 50 por chamada
  my ($ids, $props) = @_; my %out;
  for (my $i = 0; $i < @$ids; $i += 50) {
    my @c = @$ids[$i .. ($i + 49 < $#$ids ? $i + 49 : $#$ids)];
    my $d = getj('https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&props=' . ($props // 'claims|sitelinks|labels') . '&languages=pt|en|es&ids=' . join('|', @c));
    %out = (%out, %{ $d->{entities} });
  }
  \%out;
}
sub save { my ($f, $d) = @_; open my $h, '>:raw', "$ROOT/$f" or die "$f: $!"; print $h JSON::PP->new->utf8->canonical->pretty->encode($d); close $h; }
sub load { my $f = shift; open my $h, '<:raw', "$ROOT/$f" or die "$f: $!"; local $/; $JSON->decode(<$h>) }
1;
