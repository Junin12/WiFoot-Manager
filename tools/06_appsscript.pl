# Passo 6: gera os arquivos HTML do projeto do Google Apps Script (pasta appsscript/).
#   Index.html -> o jogo, com os dados incluídos pelo servidor (<?!= include('Dados') ?>)
#   Dados.html -> o pacote de dados (data_real.js se existir; senão, data.js)
use strict; use warnings; use FindBin;
my $root = "$FindBin::Bin/..";
sub slurp { open my $h, '<:raw', $_[0] or die "$_[0]: $!"; local $/; my $s = <$h>; $s }
sub put { open my $h, '>:raw', $_[0] or die "$_[0]: $!"; print $h $_[1]; close $h; printf "%s: %.0f KB\n", $_[0] =~ s/.*\///r, length($_[1]) / 1024 }
my $html = slurp("$root/index.html");
$html =~ s{<script src="data\.js"></script>\s*<script src="data_real\.js"></script>\n?}{<?!= include('Dados') ?>\n} or die "tags de dados não encontradas";
put("$root/appsscript/Index.html", $html);
my $data = -f "$root/data_real.js" ? slurp("$root/data_real.js") : slurp("$root/data.js");
put("$root/appsscript/Dados.html", "<script>\n$data</script>\n");
