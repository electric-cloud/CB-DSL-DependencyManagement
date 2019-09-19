use strict;
use warnings;
use File::Spec;
use Digest::MD5;
use Data::Dumper;
use JSON;

my %files = ();
read_dir('./agent/deps');

my $text = encode_json(\%files);
open my $fh, ">dsl/properties/ec_binary_dependencies" or die $!;
print $fh $text;
close $fh;


sub read_dir {
    my ($dir) = @_;

    opendir my $dh, $dir or die $!;
    for my $file (readdir $dh) {
        next if $file =~ /^\./;
        my $filename = File::Spec->catfile($dir, $file);
        if (-d $filename) {
            read_dir($filename);
        }
        else {
            my $digest = Digest::MD5->new;
            open my $fh, $filename or die $!;
            $digest->addfile($fh);
            my $checksum = $digest->hexdigest;
            $files{$filename} = $checksum;
        }
    }
}
