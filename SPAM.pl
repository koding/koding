#!/usr/bin/perl -w
# Hemp cURL
# Spammers mode ON
 
use strict;
use Net::SMTP::TLS;
 
die("$0 <uberpluscupon@gmail.com> <5idy4mcs> <gian.ufscar.cso@gmail.com
gabyzechel@hotmail.com
50cents55mcs@gmail.com
debora.maffei@bol.com.br
carolinaof.cf@gmail.com
deborahdrugovick@gmail.com
polianadesouza1@hotmail.com
reh-menezes@hotmail.com
alianefreitas@hotmail.com
lays.xaviercr@gmail.com
cleitondealmeida.adm@gmail.com
anaajullia@hotmail.com
ma_branquinho@yahoo.com.br
Otavioenfi@gmail.com
debora_panini@hotmail.com
fprado.ufscar@gmail.com
analpca@gmail.com
marianee-t@hotmail.com
vivianecassimiro43@gmail.com
m-p_a@hotmail.com
Marciaalvesmattos@hotmail.com
fercrisousa@hotmail.com
suhh010@gmail.com
renato_nicoletti@hotmail.com
Carolcmelo_9@hotmail.com
karentrindad@gmail.com
andrezalongati@gmail.com
alvinhorgc@hotmail.com
thiagopama@hotmail.com
Juzanollo@yahoo.com.br
Robertadellavanzi2@gmail.com
juh.garcez2@gmail.com
Hmc_black_2@hotmail.com
eme.muller@hotmail.com
bianca_sjc_aguiar@outlook.com
camilazbragatto@hotmail.com.com
glauco.domingues1@gmail.com
giovanni-milani@uol.com.br
tomreisprojetos@yahoo.com.br
rayssaramdohr@hotmail.com
sararaquelsantos@gabyzechel@hotmail.com
50cents55mcs@gmail.com
debora.maffei@bol.com.br
carolinaof.cf@gmail.com
deborahdrugovick@gmail.com
polianadesouza1@hotmail.com
reh-menezes@hotmail.com
alianefreitas@hotmail.com
lays.xaviercr@gmail.com
cleitondealmeida.adm@gmail.com
anaajullia@hotmail.com
ma_branquinho@yahoo.com.br
Otavioenfi@gmail.com
debora_panini@hotmail.com
fprado.ufscar@gmail.com
analpca@gmail.com
marianee-t@hotmail.com
vivianecassimiro43@gmail.com
m-p_a@hotmail.com
Marciaalvesmattos@hotmail.com
fercrisousa@hotmail.com
suhh010@gmail.com
renato_nicoletti@hotmail.com
Carolcmelo_9@hotmail.com
karentrindad@gmail.com
andrezalongati@gmail.com
alvinhorgc@hotmail.com
thiagopama@hotmail.com
Juzanollo@yahoo.com.br
Robertadellavanzi2@gmail.com
juh.garcez2@gmail.com
Hmc_black_2@hotmail.com
eme.muller@hotmail.com
bianca_sjc_aguiar@outlook.com
camilazbragatto@hotmail.com.com
glauco.domingues1@gmail.com
giovanni-milani@uol.com.br
tomreisprojetos@yahoo.com.br
rayssaramdohr@hotmail.com
sararaquelsantos@outlook.com.br
katy.spereira@gmail.com
d.romagnolo@hotmail.com
carvalhocaique7@gmail.com
kaserati@hotmail.com
dqmonteiro@gmail.com
ingrydrpassos@gmail.com
klausner17@gmail.com
heloisabertolli@gmail.com
yumii.caa@hotmail.com
tatiqueirozs@gmail.com
matheus.bnovaes@hotmail.com
amanda_alabarce@hotmail.com
fannyn_elisa@hotmail.com
thekarsh@hotmail.com
edsonfidback@gmail.com
cintia.atn@gmail.comoutlook.com.br
katy.spereira@gmail.com
d.romagnolo@hotmail.com
carvalhocaique7@gmail.com
kaserati@hotmail.com
dqmonteiro@gmail.com
ingrydrpassos@gmail.com
klausner17@gmail.com
heloisabertolli@gmail.com
yumii.caa@hotmail.com
tatiqueirozs@gmail.com
matheus.bnovaes@hotmail.com
amanda_alabarce@hotmail.com
fannyn_elisa@hotmail.com
thekarsh@hotmail.com
edsonfidback@gmail.com
cintia.atn@gmail.com
gabriel_errera@yahoo.com.br
alana2pereira@hotmail.com
samarafc_@hotmail.com
luzian_arruda@hotmail.com
brunspeed@hotmail.com
cristina.abujanra@hotmail.com
sorabadji@hotmail.com
rcmenegoci@msn.com
joaoguardabaxo012@gmail.com
cavalcante.leandro@gmail.com
helotomaz@hotmail.com
vitor-p> <Olá, prezado Cliente, Cadastre-se já na (Uber) e ganhe 1 Cupon Grátis de R$150 para viajar grátis nesse CARNAVAL! link: http://bit.ly/30FgMti> <Uber/informa>") if(@ARGV != 5);
my($user,$pass,$email,$eng,$assunto) = @ARGV;
my $smtp = new Net::SMTP::TLS(
 'smtp.gmail.com',
 Port    => 587,
 User    => $user,
 Password=> $pass,
 Timeout => 30
) || die($!);
 
open(EMAILS,'<'.$email) || die($!);
my @emails = <emails>;
close(EMAILS);
open(ENG,'<'.$eng) || die($!);
my @e = <eng>;
my $en = join('',@e);
close(ENG);
 
foreach(@emails){
 chomp($_);
 $smtp->mail($user);
 $smtp->recipient($_);
 $smtp->data();
 $smtp->datasend("To: $_\n");
 $smtp->datasend("From: Uber/informa <$user>\n");
 $smtp->datasend("Content-Type: text/html \n");
 $smtp->datasend("Subject: $assunto");
 $smtp->datasend("\n");
 $smtp->datasend("$en");
 $smtp->datasend("\n");
 $smtp->dataend();
 print "Enviado para $_\n";
}
 
$smtp->quit;
H3mp coding...
