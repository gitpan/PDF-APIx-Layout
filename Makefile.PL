#!perl
#=======================================================================
#    ____  ____  _____           _                            _
#   |  _ \|  _ \|  ___|  _   _  | |    __ _ _   _  ___  _   _| |_
#   | |_) | | | | |_    (_) (_) | |   / _` | | | |/ _ \| | | | __|
#   |  __/| |_| |  _|    _   _  | |__| (_| | |_| | (_) | |_| | |_
#   |_|   |____/|_|     (_) (_) |_____\__,_|\__, |\___/ \__,_|\__|
#                                           |___/
#
#   A Perl Module Chain to faciliate Layouts for PDF::API2.
#
#   Copyright 1999-2005 Alfred Reibenschuh <areibens@cpan.org>.
#
#=======================================================================
#
#   THIS LIBRARY IS FREE SOFTWARE; YOU CAN REDISTRIBUTE IT AND/OR
#   MODIFY IT UNDER THE TERMS OF THE GNU LESSER GENERAL PUBLIC
#   LICENSE AS PUBLISHED BY THE FREE SOFTWARE FOUNDATION; EITHER
#   VERSION 2 OF THE LICENSE, OR (AT YOUR OPTION) ANY LATER VERSION.
#
#   THIS FILE IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL,
#   AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
#   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
#   SHALL THE AUTHORS AND COPYRIGHT HOLDERS AND THEIR CONTRIBUTORS 
#   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
#   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
#   OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
#   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, 
#   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
#   ARISING IN ANY WAY OUT OF THE USE OF THIS FILE, EVEN IF 
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#   SEE THE GNU LESSER GENERAL PUBLIC LICENSE FOR MORE DETAILS.
#
#   YOU SHOULD HAVE RECEIVED A COPY OF THE GNU LESSER GENERAL PUBLIC
#   LICENSE ALONG WITH THIS LIBRARY; IF NOT, WRITE TO THE
#   FREE SOFTWARE FOUNDATION, INC., 59 TEMPLE PLACE - SUITE 330,
#   BOSTON, MA 02111-1307, USA.
#
#   $Id: $
#
#=======================================================================

require 5.008;

use ExtUtils::MakeMaker;

my $versionfile = "version.pmf";

require "$versionfile";

my %makehash=( 
    NAME            => "PDF::APIx::Layout", 
    AUTHOR          => "areibens\@cpan.org", 
    ABSTRACT        => "PDF Layout API", 
    dist            => { 
        ZIP         => "zip ", 
        ZIPFLAGS    => " -v -o -r -9 ",
        COMPRESS    => "gzip -9 -f ", 
    }, 
    MAN1PODS        => {}, 
    MAN3PODS        => {}, 
    PREREQ_PM       => { 'PDF::API2' => 0.46, }, 
    VERSION_FROM    => $versionfile,
    BINARY_LOCATION => q|PDF-APIx-Layout-|.$PDF::APIx::Layout::Version::CVersion{vPerl}.q|.ppm.tar.gz|,
);

WriteMakefile( %makehash );

print STDERR $PDF::APIx::Layout::Version::CVersion{vTeX}."\n";

exit;

sub MY::postamble{
    my $y=qq|ppmdist: pm_to_blib ppd dist\n|;
    $y.=qq|\t\$(MKPATH) \$(DISTNAME)-\$(VERSION)-PPM\n|;
    $y.=qq|\t\$(TAR) \$(TARFLAGS) \$(DISTNAME)-\$(VERSION)-PPM/\$(DISTNAME)-\$(VERSION).ppm.tar blib\n|;
    $y.=qq|\t\$(COMPRESS) \$(DISTNAME)-\$(VERSION)-PPM/\$(DISTNAME)-\$(VERSION).ppm.tar\n|;
    $y.=qq|\t\$(CP) \$(DISTNAME).ppd \$(DISTNAME)-\$(VERSION)-PPM/\$(DISTNAME).ppd\n|;
    $y.=qq|\t\$(ZIP) \$(ZIPFLAGS) \$(DISTNAME)-\$(VERSION).\$(OSNAME)-\$(OSVERS).ppm.zip \$(DISTNAME)-\$(VERSION)-PPM/\$(DISTNAME)-\$(VERSION).ppm.tar.gz \$(DISTNAME)-\$(VERSION)-PPM/\$(DISTNAME).ppd\n|;
    $y.=qq|\t\$(RM_RF) \$(DISTNAME)-\$(VERSION)-PPM\n|;
    $y.=qq|\n|;
    return($y);
}

__END__
