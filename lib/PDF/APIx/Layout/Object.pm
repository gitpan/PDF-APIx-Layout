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

package PDF::APIx::Layout::Object;

BEGIN 
{
    use utf8;
    use Encode qw(:all);
    use PDF::API2::Util;

    use vars qw( $VERSION );

    ($VERSION) = '$Revision: $' =~ /Revision: (\S+)\s/; # $Date: $
}

no warnings qw[ deprecated recursion uninitialized ];

sub new 
{
    my ($class,%opts) = @_;
    my $self={};
    
    bless($self, ref($class) ? ref($class) : $class);

    $self->{-w}=0;
    $self->{-h}=0;

    $self->{-colspan}=1;
    $self->{-rowspan}=1;

    foreach my $k (keys %opts)
    {
        $self->{$k}=$opts{$k};
        if($k eq '-width')
        {
            $self->{-w}=$opts{$k};    
            $self->{-minw}=$opts{$k};    
        }
        elsif($k eq '-height')
        {
            $self->{-h}=$opts{$k};    
            $self->{-minh}=$opts{$k};    
        }
    }

    return($self);
}

sub isAtomic
{
    my $self=shift @_;
    return(1);
}

sub colSpan
{
    my $self=shift @_;
    return($self->{-colspan});
}

sub rowSpan
{
    my $self=shift @_;
    return($self->{-rowspan});
}

sub width
{
    return($_[0]->{-w});
}

sub height
{
    return($_[0]->{-h});
}

sub isReflowAble
{
    my $self=shift @_;
    return(0);
}

sub minWidth
{
    return($_[0]->{-minw});
}

sub minHeight
{
    return($_[0]->{-minh});
}

sub maxWidth
{
    return($_[0]->{-maxw});
}

sub maxHeight
{
    return($_[0]->{-maxh});
}

sub heightByWidth
{
    return($_[0]->{-h}*$_[1]/$_[0]->{-w});
}

sub widthByHeight
{
    return($_[0]->{-w}*$_[1]/$_[0]->{-h});
}

sub _adjust_for_margins
{
    my ($self,$x,$y,$w,$h)=@_;
    # correct x,y,w,h for margins
    
    $w-=($self->{-marginleft} || $self->{-margin});
    $w-=($self->{-marginright} || $self->{-margin});
    $x+=($self->{-marginleft} || $self->{-margin});
    
    $h-=($self->{-margintop} || $self->{-margin});
    $h-=($self->{-marginbottom} || $self->{-margin});
    $y-=($self->{-margintop} || $self->{-margin});
    
    return($x,$y,$w,$h);
}

sub _adjust_for_padding
{
    my ($self,$x,$y,$w,$h)=@_;
    # correct x,y,w,h for margins
    
    $h-=($self->{-paddingtop} || $self->{-padding});
    $h-=($self->{-paddingbottom} || $self->{-padding});
    
    $w-=($self->{-paddingleft} || $self->{-padding});
    $w-=($self->{-paddingright} || $self->{-padding});
    
    $x+=($self->{-paddingleft} || $self->{-padding});
    $y-=($self->{-paddingtop} || $self->{-padding});
    
    return($x,$y,$w,$h);
}

sub _render_bg_border
{
    my ($self,$pdf,$page,$gfx,$x,$y,$w,$h)=@_;

    $gfx->save;

    if(defined $self->{-background-transparency})
    {
        my $egs=$pdf->egstate;
        $egs->transparency($self->{-background-transparency});
        $gfx->egstate($egs);
    }
    
    if($self->{-background})
    {
        $gfx->save;
        if(ref $self->{-background})
        {
            $gfx->fillcolor(@{$self->{-background}});
        }
        else
        {
            $gfx->fillcolor($self->{-background});
        }
        $gfx->rect($x,$y-$h,$w,$h);
        $gfx->fill;
        $gfx->restore;
    }

    if($self->{-border})
    {
        $gfx->save;
        $gfx->linewidth($self->{-border});
        if($self->{-borderdash})
        {
            $gfx->linedash(@{$self->{-borderdash}});
        }
        if(ref $self->{-bordercolor})
        {
            $gfx->strokecolor(@{$self->{-bordercolor}});
        }
        else
        {
            $gfx->strokecolor($self->{-bordercolor});
        }
        $gfx->rect($x,$y-$h,$w,$h);
        $gfx->stroke;
        $gfx->restore;
    }
    else
    {
        my @cc=(
            [$x,$y],
            [$x,$y-$h],
            [$x+$w,$y-$h],
            [$x+$w,$y],
            [$x,$y],
        );
        foreach my $k (qw[ left bottom right top ])
        {
            if($self->{"-border$k"} || $self->{-border})
            {
                $gfx->save;
                $gfx->linewidth($self->{"-border$k"} || $self->{-border});
                if($self->{-borderdash})
                {
                    $gfx->linedash(@{$self->{-borderdash}});
                }
                elsif($self->{"-border$k"."dash"})
                {
                    $gfx->linedash(@{$self->{"-border$k"."dash"}});
                }

                if(ref $self->{"-border$k"."color"})
                {
                    $gfx->strokecolor(@{$self->{"-border$k"."color"}});
                }
                elsif($self->{"-border$k"."color"})
                {
                    $gfx->strokecolor($self->{"-border$k"."color"});
                }
                elsif(ref $self->{-bordercolor})
                {
                    $gfx->strokecolor(@{$self->{-bordercolor}});
                }
                elsif($self->{-bordercolor})
                {
                    $gfx->strokecolor($self->{-bordercolor});
                }

                $gfx->move(@{$cc[0]});
                $gfx->line(@{$cc[1]});
                $gfx->stroke;
                $gfx->restore;
            }
            shift @cc;
        }
    }

    $gfx->restore;
    
    return(undef);
}

sub render
{
    my ($self,$pdf,$page,$gfx,$x,$y,$w,$h)=@_;
    my $obj=0;
    
    $gfx->metaStart(pdfkey());
    $gfx->save;

    ($x,$y,$w,$h)=$self->_adjust_for_margins($x,$y,$w,$h);

    if(defined $self->{-id})
    {
        $pdf->named_destination('Dests','#'.$self->{-id})->link($page);
    }        
    if(defined $self->{-href})
    {
        my $at=$page->annotation;
        $at->rect($x,$y-$h,$x+$w,$y);
        if($self->{-href}=~m|^#|)
        {
            $at->link($self->{-href});
        }
        else
        {
            $at->url($self->{-href});
        }
    }        

    $self->_render_bg_border($pdf,$page,$gfx,$x,$y,$w,$h);

    $gfx->rect($x,$y-$h,$w,$h);
    $gfx->clip;
    $gfx->endpath;

    ($x,$y,$w,$h)=$self->_adjust_for_padding($x,$y,$w,$h);

    $obj=$self->_render($pdf,$page,$gfx, $x, $y, $w, $h);

    $gfx->restore;
    $gfx->metaEnd;
    
    return($obj) if($obj);
    
    return(undef);
}


1;

__END__

=head1 AUTHOR

alfred reibenschuh

=head1 HISTORY

    $Log: $

=cut
