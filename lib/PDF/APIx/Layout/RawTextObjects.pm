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

package PDF::APIx::Layout::RawTextObjects;

BEGIN 
{
    use utf8;
    use Encode qw(:all);

    use PDF::API2::UniWrap;
    use PDF::APIx::Layout::Object;

    use vars qw( @ISA $VERSION $BlockJustification $BlockExpansion);

    @ISA=qw[ PDF::APIx::Layout::Object ];

    ($VERSION) = '$Revision: $' =~ /Revision: (\S+)\s/; # $Date: $
}

no warnings qw[ deprecated recursion uninitialized ];

$BlockJustification=1.1;
$BlockExpansion=1.2;

sub _new
{
    my ($class,%opts) = @_;
    
    $class = ref($class) ? ref($class) : $class;

    my $self=$class->SUPER::new(%opts);
    
    $self->{-lead}||=1;

    $self->{-maxw}||=0;
    $self->{-minw}||=0;
    $self->{-maxh}||=0;
    $self->{-minh}||=0;

    $self->{-h}||=0;
    $self->{-w}||=0;
    
    return($self);
}

sub _calc_w_space
{
    my $chunk=shift @_;
    my ($style,$attr,$text)=@{$chunk};

    $attr->{calcwidth}=$style->{-fontsize}*$style->{-font}->width($text)*($style->{-hspace}/100);
    $attr->{calcheight}=$style->{-lead};
}

sub _calc_wo_space
{
    my $chunk=shift @_;
    my ($style,$attr,$text)=@{$chunk};
    $text=~s|\s+$||g;
    $attr->{calcuwidth}=$style->{-fontsize}*$style->{-font}->width($text)*($style->{-hspace}/100);
    $attr->{calcuheight}=$style->{-lead};
}

sub _proc_objects
{
    my ($self,$textobjs) = @_;

    $self->{-text}=[ @{$textobjs} ];
    my $lastHeight=0;
    foreach my $chunk ( @{$self->{-text}} )
    {
        my ($style,$attr,$text)=@{$chunk};
        if(scalar @{$chunk})
        {
            $style->{-font} ||= $self->{-font};
            $style->{-fontsize} ||= $self->{-fontsize} || 10;
            $style->{-textcolor} ||= $self->{-textcolor} || 'black';
            $style->{-lead} ||= $style->{-fontsize}*$self->{-lead};
            $style->{-hspace} ||= 100;

            _calc_w_space($chunk);
            _calc_wo_space($chunk);
        }
        else
        {
            $chunk->[0]=undef;
            $chunk->[1]={};
            $chunk->[1]->{forcebreak}=1;
            $chunk->[1]->{calcwidth}=0;
            $chunk->[1]->{calcheight}=$lastHeight;
            $chunk->[1]->{calcuwidth}=0;
            $chunk->[1]->{calcuheight}=$lastHeight;
            $chunk->[2]='';
            $attr=$chunk->[1];
        }
        
        if($self->{-minw} <= $attr->{calcwidth})
        {
            $self->{-minw}=$attr->{calcwidth};
        }
        $self->{-maxw}+=$attr->{calcwidth};

        if($self->{-minh} <= $attr->{calcheight})
        {
            $self->{-minh}=$attr->{calcheight};
        }
        $self->{-maxh}+=$attr->{calcheight};
        $lastHeight=$attr->{calcheight};
    }

    $self->{-maxw}+=($self->{-paddingleft} || $self->{-padding});
    $self->{-maxw}+=($self->{-paddingright} || $self->{-padding});
    $self->{-maxw}+=($self->{-marginleft} || $self->{-margin});
    $self->{-maxw}+=($self->{-marginright} || $self->{-margin});

    $self->{-minw}+=($self->{-paddingleft} || $self->{-padding});
    $self->{-minw}+=($self->{-paddingright} || $self->{-padding});
    $self->{-minw}+=($self->{-marginleft} || $self->{-margin});
    $self->{-minw}+=($self->{-marginright} || $self->{-margin});

    $self->{-maxh}+=($self->{-paddingtop} || $self->{-padding});
    $self->{-maxh}+=($self->{-paddingbottom} || $self->{-padding});
    $self->{-maxh}+=($self->{-margintop} || $self->{-margin});
    $self->{-maxh}+=($self->{-marginbottom} || $self->{-margin});
    
    $self->{-minh}+=($self->{-paddingtop} || $self->{-padding});
    $self->{-minh}+=($self->{-paddingbottom} || $self->{-padding});
    $self->{-minh}+=($self->{-margintop} || $self->{-margin});
    $self->{-minh}+=($self->{-marginbottom} || $self->{-margin});
    
    $self->{-w}=$self->{-maxw};
    $self->{-h}=$self->{-minh};

    $self->{-words}=scalar @{$self->{-text}};

    $self->{-wcache}={};

    return($self);
}

sub new 
{
    my ($class,$textobjs,%opts) = @_;
    
    $class = ref($class) ? ref($class) : $class;

    my $self=$class->_new(%opts);
    $self->_proc_objects($textobjs);    

    return($self);
}

sub isReflowAble
{
    my $self=shift @_;
    return(1);
}

sub heightByWidth
{
    my ($self,$w)=@_;

    $w-=($self->{-paddingleft} || $self->{-padding});
    $w-=($self->{-paddingright} || $self->{-padding});
    $w-=($self->{-marginleft} || $self->{-margin});
    $w-=($self->{-marginright} || $self->{-margin});

    if(exists $self->{-wcache}->{$w})
    {
        return($self->{-wcache}->{$w});
    }
    
    my $wx=0;
    my $wf=$self->{-align} eq 'j' ? ($self->{-blockjustify} || $BlockJustification) : 1;
    my $h=0;
    my @t;
    
    foreach my $chunk ( @{$self->{-text}} )
    {
        if(((($w*$wf) <= ($wx+$chunk->[1]->{calcuwidth})) && (scalar @t > 0)) || $chunk->[1]->{forcebreak})
        {
            my $hx=0;
            $wx=0;
            map { if($hx < $_->[1]->{calcheight}){ $hx=$_->[1]->{calcheight}; } } @t;
            $h+=$hx;
            @t=();
        }

        $wx+=$chunk->[1]->{calcwidth};
        push @t,$chunk;
    }

    if(scalar @t > 0)
    {
        my $hx=0;
        $wx=0;
        map { if($hx < $_->[1]->{calcheight}){ $hx=$_->[1]->{calcheight}; } } @t;
        $h+=$hx;
        @t=();
    }
    
    $h+=($self->{-paddingtop} || $self->{-padding});
    $h+=($self->{-paddingbottom} || $self->{-padding});
    $h+=($self->{-margintop} || $self->{-margin});
    $h+=($self->{-marginbottom} || $self->{-margin});
    
    $self->{-wcache}->{$w}=$h;
    
    return($h);
}

sub widthByHeight
{
    my ($self,$h)=@_;

    $h-=($self->{-paddingtop} || $self->{-padding});
    $h-=($self->{-paddingbottom} || $self->{-padding});
    $h-=($self->{-margintop} || $self->{-margin});
    $h-=($self->{-marginbottom} || $self->{-margin});
    
# TODO

    my $w=0;

# TODO

    $w+=($self->{-paddingleft} || $self->{-padding});
    $w+=($self->{-paddingright} || $self->{-padding});
    $w+=($self->{-marginleft} || $self->{-margin});
    $w+=($self->{-marginright} || $self->{-margin});
    
    return($w);
}

sub _render
{
    my ($self,$pdf,$page,$txt,$x,$y,$w,$h)=@_;

    $txt->textstart;
    $txt->transform(-translate => [ $x, $y ]);
    
    my $wx=0; 
    my $wf=$self->{-align} eq 'j' ? ($self->{-blockjustify} || $BlockJustification) : 1; 
    my @t=(); 
    my @rend=();
    foreach my $chunk ( @{$self->{-text}} )
    {
        my ($style,$attr,$text)=@{$chunk};
        if(((($w*$wf) <= ($wx+$attr->{calcuwidth})) && (scalar @t > 0)) || $attr->{forcebreak})
        {
            push @rend,[$attr->{forcebreak} || 0,@t];
            $wx=0; @t=();
        }    
        $wx+=$attr->{calcwidth};
        next unless(defined $style);
        push @t,$chunk;
    }
    if(scalar @t > 0)
    {
        push @rend,[0,@t];
        @t=();
    }
        
    $rend[-1]->[0]=1;
    
    my $line=0;
    my $hl=0; my $of=0;
    foreach my $tline (@rend)
    {
        my $islast=shift(@{$tline});
        my $hx=0;
        $wx=0;
        my $hf=0; 
        map 
        { 
            if($hf <= $_->[0]->{-fontsize}){ $hf=$_->[0]->{-fontsize}; }
            if($hx <= $_->[1]->{calcheight}){ $hx=$_->[1]->{calcheight}; }
            $wx+=$_->[1]->{calcwidth};
        } @{$tline};

        if(!$line) { $hx=$hf; }

        $wx-=$tline->[-1]->[1]->{calcwidth}-$tline->[-1]->[1]->{calcuwidth};

        if($hl+$hx<$h)
        {
            $txt->lead($hx);
            $txt->nl;
            $hl+=$hx;
            
            my $isfirst=1;
            my $laststyle=0;
            my $lasthspace=0;
            foreach my $t (@{$tline})
            {
                next unless(defined $t->[0]);
                my %txtopt=(); $txtopt{-underline}=[$t->[0]->{-fontsize}*0.20,$t->[0]->{-fontsize}*0.1] if($t->[0]->{-underline} && $t->[0]->{-underline} ne 'none');
                
                if($self->{-align} eq 'r' && $isfirst)
                {
                    $txtopt{-indent}=$w-$wx;
                }
                elsif($self->{-align} eq 'c' && $isfirst)
                {
                    $txtopt{-indent}=($w-$wx)/2;
                }

                if(($self->{-align} eq 'j') && (!$islast || ($wx>$w)))
                {
                    my $hsf=$w/$wx;
                    if(($hsf > ($self->{-blockexpand} || $BlockExpansion)) && (scalar @{$tline} > 1))
                    {
                        $hsf=($self->{-blockexpand} || $BlockExpansion);
                        $txtopt{-indent}=(($w-($wx*$hsf))/((scalar @{$tline})-1)) unless($isfirst);
                    }
                    my $hspace=($t->[0]->{-hspace} || 100)*$hsf;
                    if($lasthspace != $hspace)
                    {
                        $txt->hspace($hspace);
                    }
                    $lasthspace=$hspace;
                }
                elsif($lasthspace!=($t->[0]->{-hspace} || 100))
                {
                    $txt->hspace($t->[0]->{-hspace} || 100);
                    $lasthspace=($t->[0]->{-hspace} || 100);
                }

                if($laststyle ne $t->[0])
                {
                    $txt->font($t->[0]->{-font},$t->[0]->{-fontsize});

                    $txt->rise($t->[0]->{-rise} || 0);

                    if(ref $t->[0]->{-textcolor})
                    {
                        $txt->fillcolor(@{$t->[0]->{-textcolor}});
                    }
                    else
                    {
                        $txt->fillcolor($t->[0]->{-textcolor});
                    }
                }

                my $xy1=[$txt->textpos2];
                $txt->text($t->[2],%txtopt);
                my $xy2=[$txt->textpos2];

                if(defined $t->[0]->{-id})
                {
                    $pdf->named_destination('Dests','#'.$t->[0]->{-id})->link($page);
                }
                if(defined $t->[0]->{-href})
                {
                    my $at=$page->annotation;
                    $at->rect(
                        $txt->_textpos(@{$xy1}),
                        $txt->_textpos(@{$xy2},0,$t->[0]->{-fontsize})
                    );
                    if($t->[0]->{-href}=~m|^#|)
                    {
                        $at->link($t->[0]->{-href});
                    }
                    else
                    {
                        $at->url($t->[0]->{-href});
                    }
                }        

                if($t->[0]->{-background})
                {
                    $gfx->save;
                    if(ref $t->[0]->{-background})
                    {
                        $gfx->fillcolor(@{$t->[0]->{-background}});
                    }
                    else
                    {
                        $gfx->fillcolor($t->[0]->{-background});
                    }
                    $gfx->rectxy(
                        $txt->_textpos(@{$xy1}),
                        $txt->_textpos(@{$xy2},0,$t->[0]->{-fontsize})
                    );
                    $gfx->fill;
                    $gfx->restore;
                }
                $isfirst=0;
                $laststyle=$t->[0];
            }
            $line++;
        }
        else
        {
            unless(ref $of)
            {
                $of=[];
            }
            push @{$of}, @{$tline};
        }
    }
    $txt->textend;

    $h+=($self->{-paddingtop} || $self->{-padding});
    $h+=($self->{-paddingbottom} || $self->{-padding});
    
    $w+=($self->{-paddingleft} || $self->{-padding});
    $w+=($self->{-paddingright} || $self->{-padding});

    if(ref $of)
    {
        my $obj={%{$self}};
        bless $obj, ref($self);
        $obj->{-text}=$of;
        delete $obj->{-id};
        return($obj);
    }
    
    return(undef);
}


1;

__END__

=head1 AUTHOR

alfred reibenschuh

=head1 HISTORY

    $Log: $

=cut
