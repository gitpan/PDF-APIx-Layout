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

package PDF::APIx::Layout::FixedText;

BEGIN 
{
    use utf8;
    use Encode qw(:all);

    use PDF::APIx::Layout::RawTextObjects;

    use vars qw( @ISA $VERSION );

    @ISA=qw[ PDF::APIx::Layout::RawTextObjects ];

    ($VERSION) = '$Revision: $' =~ /Revision: (\S+)\s/; # $Date: $
}

no warnings qw[ deprecated recursion uninitialized ];

sub new 
{
    my ($class,$font,$size,$text,%opts) = @_;
    
    $class = ref($class) ? ref($class) : $class;

    $opts{-lead}||=1;
    $opts{-font}=$font;
    $opts{-fontsize}=$size;

    my $rtext=[];
    my $style={};
    foreach my $para (split(/[\r\n]/,$text))
    {
        push @{$rtext},[];
        utf8::upgrade($para);
        push @{$rtext},[$style,{},$para];
    }
    shift @{$rtext};
    
    my $self=$class->SUPER::new($rtext,%opts);

    $self->{-maxw}=0;
        
    foreach my $chunk ( @{$self->{-text}} )
    {
        if(defined $chunk->[0] && $self->{-maxw}<$chunk->[1]->{calcwidth})
        {
            $self->{-maxw}=$chunk->[1]->{calcwidth};
        }
    }

    $self->{-maxw}+=($self->{-paddingleft} || $self->{-padding});
    $self->{-maxw}+=($self->{-paddingright} || $self->{-padding});
    $self->{-maxw}+=($self->{-marginleft} || $self->{-margin});
    $self->{-maxw}+=($self->{-marginright} || $self->{-margin});

    return($self);
}

1;

__END__

=head1 AUTHOR

alfred reibenschuh

=head1 HISTORY

    $Log: $

=cut
