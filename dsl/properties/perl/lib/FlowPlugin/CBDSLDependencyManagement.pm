package FlowPlugin::CBDSLDependencyManagement;
use strict;
use warnings;
use base qw/FlowPDF/;
use FlowPDF::Log;
use JSON;
use Data::Dumper;
use File::Spec;
use File::Path qw(mkpath);
use Digest::MD5;
use MIME::Base64 qw(decode_base64);
use Archive::Zip;
use Time::HiRes qw(gettimeofday tv_interval);


# Feel free to use new libraries here, e.g. use File::Temp;

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName          => '@PLUGIN_KEY@',
        pluginVersion       => '@PLUGIN_VERSION@',
        configFields        => ['config'],
        configLocations     => ['ec_plugin_cfgs'],
        defaultConfigValues => {}
    };
}

# Auto-generated method for the procedure DeliverDependencies/DeliverDependencies
# Add your code into this method and it will be called when step runs
sub deliverDependencies {
    my ($self, $runtimeParameters, $stepResult) = @_;

    my $start = [gettimeofday];
    my $ec = ElectricCommander->new;
    my $meta = $self->readMeta();

    my @files = keys %$meta;

    my $source = $ec->getPropertyValue('/server/settings/pluginsDirectory') .'/@PLUGIN_NAME@/agent';

    my $processingFile = 0;
    my $dest = File::Spec->catfile($ENV{COMMANDER_PLUGINS}, '@PLUGIN_NAME@/agent');

    my $dsl = $ec->getPropertyValue('/myProject/compressAndDeliver.dsl');


    my $hasMore = 1;
    my $offset = 0;
    mkpath($dest);
    my $dependencies = File::Spec->catfile($dest, ".cbDependenciesTarget.zip");
    open my $fh, ">$dependencies" or die "Cannot open $dependencies: $!";
    binmode $fh;
    while($hasMore) {
        my $args = {
            offset => $offset,
            source => $source,
            chunkSize => 1024 * 1024 * 4
        };
        print "Calling evalDSl with arguments " . Dumper ($args) . "\n";
        my $xpath = $ec->evalDsl({
            dsl => $dsl,
            parameters => encode_json($args),
        });
        my $result = $xpath->findvalue('//value')->string_value;
        my $chunks = decode_json($result);
        my $chunk = $chunks->{chunk};
        my $bytes = decode_base64($chunk);
        my $remaining = $chunks->{remaining};
        print "Got bytes: " . length($bytes) . "\n";
        print "Bytes remaining: " . $remaining . "\n";
        my $readBytes = $chunks->{readBytes};
        $offset += $readBytes;
        print "Read bytes: $readBytes\n";
        if ($readBytes > 0) {
            print $fh $bytes;
        }
        if ($remaining == 0 || $readBytes <= 0) {
            $hasMore = 0;
        }
    }
    close $fh;

    my $t0 = [gettimeofday];

    my $zip = Archive::Zip->new();
    unless($zip->read($dependencies) == Archive::Zip::AZ_OK()) {
      die "Cannot read .zip dependencies: $!";
    }
    $zip->extractTree("", $dest . '/');


    print "Extracted dependencies archive\n";
    my $elapsed = tv_interval ( $t0 );
    print "Elapsed time (extraction): $elapsed seconds\n";

    my $total = tv_interval($start);
    print "Total time spent in step code: $total seconds\n";
    # my $cacheValid = 1;
    # for my $file (@files) {
    #     my $fullFilename = File::Spec->catfile($dest, $file);
    #     unless(-f $fullFilename) {
    #         logInfo "File $fullFilename does not exist, cache is invalid";
    #         $cacheValid = 0;
    #         last;
    #     }
    #     my $digest = Digest::MD5->new;
    #     open(my $fh, $fullFilename);
    #     if (!$fh) {
    #         logInfo "File $fullFilename cannot be opened, cache is invalid";
    #         $cacheValid = 0;
    #         last;
    #     }
    #     binmode $fh;
    #     $digest->addfile($fh);
    #     if ($digest->hexdigest ne $meta->{$file}) {
    #         $cacheValid = 0;
    #         logInfo "Checksums do not match for file $file, cache is invalid";
    #         last;
    #     }
    # }
    # if ($cacheValid) {
    #     logInfo "Local cache is valid, no further action required";
    #     exit 0;
    # }

    # # TODO lock
    # my $dsl = $ec->getPropertyValue('/myProject/deliver.dsl');
    # while($processingFile < scalar @files) {
    #     my $args = {
    #         files => \@files,
    #         source => $source,
    #         startWithFile => $processingFile,
    #         chunkSize => 1024 * 1024 * 4
    #     };
    #     logInfo "Calling DSL with arguments ", $args;
    #     my $result = $ec->evalDsl({
    #         dsl => $dsl,
    #         parameters => encode_json($args)
    #     });
    #     my $json = $result->findvalue('//value')->string_value;
    #     $json = decode_json($json);
    #     my $chunk = $json->{chunk};
    #     my $ci = 0;
    #     for my $file (@$chunk) {
    #         my $filename = $files[$ci + $processingFile];
    #         logInfo "Processing file $filename";
    #         my $path = File::Spec->catfile($dest, $filename);
    #         my ($v, $d, $f) = File::Spec->splitpath($path);
    #         my $parentDir = File::Spec->catpath($v, $d);
    #         mkpath($parentDir);
    #         my $binary = decode_base64($file);
    #         my $context = Digest::MD5->new;
    #         $context->add($binary);
    #         my $checksum = $context->hexdigest;

    #         if ($checksum ne $meta->{$filename}) {
    #             die "Checksum failed for file $filename: $checksum and $meta->{$filename}";
    #         }

    #         open my $fh, ">$path" or die "Cannot open $path: $!";
    #         binmode $fh;
    #         print $fh $binary;
    #         close $fh;
    #         logInfo "Saved file $path";
    #         $ci ++;
    #     }
    #     $processingFile += $ci;
    # }
}
## === step ends ===
# Please do not remove the marker above, it is used to place new procedures into this file.


sub readMeta {
    my ($self) = @_;
    my $ec = ElectricCommander->new;
    my $json = $ec->getPropertyValue('/myProject/ec_binary_dependencies');
    my $meta = decode_json($json);
    return $meta;
}

1;
