use strict;
package Siesta::Build;
use Module::Build;
use File::Find qw(find);
use IO::File;
use base 'Module::Build';
use vars qw/$FAKE/;

sub create_build_script {
    my $self = shift;
    $self->SUPER::create_build_script;

    # check for incompatible steps
    my $module = $self->{properties}{module_name};
    if (my $version = $self->check_installed_version($module, 0)) {
        print "Upgrading from $module $version\n";
        my $fh = IO::File->new('Changes');
        local $/ = "\n\n\n";
        while (<$fh>) {
            next unless /^(\S+)/;
            my $chunk = $_; # check installed version stomps $_
            my $this = $1;
            last if $self->check_installed_version( $module, $this );
            print "Incompatible changes were introducted in version $this:\n",
              $chunk
                if $chunk =~ /INCOMPATIBLE/s;
        }
    }
}

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
    $self->ACTION_install_extras;
}

sub ACTION_fakeinstall {
    my $self = shift;
    $self->SUPER::ACTION_fakeinstall;
    local $FAKE = 1;
    $self->ACTION_install_extras;
}

sub ACTION_install_extras {
    my $self = shift;
    my $path = $self->{config}{__extras_destination};
    my @files = $self->_find_extras;
    print "installing extras to $path\n";
    for (@files) {
        $FAKE
          ? print "$_ -> $path/$_ (FAKE)\n"
          : $self->copy_if_modified($_, $path);
    }
}

sub _find_extras {
    my $self = shift;
    my @files;
    find(sub {
             $File::Find::prune = 1 if -d && /^\.svn$/;
             return if -d;
             return if /~$/;
             push @files, $File::Find::name;
         }, @{ $self->{config}{__extras_from} });
    return @files;
}

1;
