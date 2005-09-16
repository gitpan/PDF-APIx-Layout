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

package PDF::APIx::Layout::BasicGrid;

BEGIN 
{
    use utf8;
    use Encode qw(:all);

    use PDF::APIx::Layout::Object;

    use vars qw( @ISA $VERSION);

    @ISA=qw[ PDF::APIx::Layout::Object ];

    ($VERSION) = '$Revision: $' =~ /Revision: (\S+)\s/; # $Date: $
}

no warnings qw[ deprecated recursion uninitialized ];


sub _new
{
    my ($class,%opts) = @_;
    
    $class = ref($class) ? ref($class) : $class;

    my $self=$class->SUPER::new(%opts);
    
    $self->{-maxw}||=0;
    $self->{-minw}||=0;
    $self->{-maxh}||=0;
    $self->{-minh}||=0;

    $self->{-fixw}||=[];

    $self->{-h}||=0;
    $self->{-w}||=0;

    $self->{-rowdata}=[];    
    $self->{-coldata}=[];    

    $self->{-maxrows}=0;    
    $self->{-maxcols}=0;    

    $self->{-rows}=[];    
    
    return($self);
}

sub new 
{
    my ($class,%opts) = @_;
    
    $class = ref($class) ? ref($class) : $class;

    my $self=$class->_new(%opts);

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

    # $w-=($self->{-paddingleft} || $self->{-padding});
    # $w-=($self->{-paddingright} || $self->{-padding});
    # $w-=($self->{-marginleft} || $self->{-margin});
    # $w-=($self->{-marginright} || $self->{-margin});

    my $wx=$w-$self->{-minw} < 0 ? 0 : $w-$self->{-minw};
    $wx/=$self->{-maxcols};

    map { $_->{-avgh}=0; $_->{-avgw}=0; } @{$self->{-rowdata}};

    for(my $c=0 ; $c<$self->{-maxcols} ; $c++)
    {
        $self->{-coldata}->[$c]->{-avgh}=0; 
        $self->{-coldata}->[$c]->{-avgw}=$self->{-coldata}->[$c]->{-minw}+$wx;
        # print STDERR qq[=(c=$c): aw=$self->{-coldata}->[$c]->{-avgw} mw=$self->{-coldata}->[$c]->{-maxw} ];
        if($self->{-coldata}->[$c]->{-avgw}>$self->{-coldata}->[$c]->{-maxw} && $c<$self->{-maxcols}-1)
        {
            my $v=$self->{-coldata}->[$c]->{-avgw}-$self->{-coldata}->[$c]->{-maxw};
            
            $wx+=$v/($self->{-maxcols}-$c-1);
            
            $self->{-coldata}->[$c]->{-avgw}=$self->{-coldata}->[$c]->{-maxw};
        }

        if($self->{-fixw}->[$c] && $c<$self->{-maxcols}-1)
        {
            my $v=$self->{-coldata}->[$c]->{-avgw}-$self->{-fixw}->[$c];
            
            $wx+=$v/($self->{-maxcols}-$c-1);
            
            $self->{-coldata}->[$c]->{-avgw}=$self->{-fixw}->[$c];
        }
        # print STDERR qq[aw(F)=$self->{-coldata}->[$c]->{-avgw} \n];
    }
    
    for(my $c=0 ; $c<$self->{-maxcols} ; $c++)
    {
        $self->{-coldata}->[$c]->{-avgh}=0;
        for(my $r=0 ; $r<$self->{-maxrows} ; $r++)
        {
            my $cell=$self->{-rows}->[$r]->[$c];
            if(ref $cell)
            {
                my $ch=0; my $cw=0;
                my $rs=$cell->rowSpan;
                my $cs=$cell->colSpan;
                while($r+$rs>$self->{-maxrows}) {$rs--};
                while($c+$cs>$self->{-maxcols}) {$cs--};
        
                for(my $i=0 ; $i<$cs ; $i++)
                {
                    $cw+=$self->{-coldata}->[$c+$i]->{-avgw};
                }
                
                if($cell->isReflowAble())
                {
                    $ch=$cell->heightByWidth($cw);
                }
                else
                {
                    $ch=$cell->height();
                }
                
                $self->{-coldata}->[$c]->{-avgh}+=$ch;
                # print STDERR qq[=($r:$c): cw=$cw ch=$ch\n];
            }
        }
    }

    for(my $r=$self->{-maxrows}-1 ; $r>=0; $r--)
    {
        for(my $c=$self->{-maxcols}-1 ; $c>=0; $c--)
        {
            my $cell=$self->{-rows}->[$r]->[$c];
            if(ref $cell)
            {
                my $ch=0; my $cw=0;
                my $rs=$cell->rowSpan;
                my $cs=$cell->colSpan;
                while($r+$rs>$self->{-maxrows}) {$rs--};
                while($c+$cs>$self->{-maxcols}) {$cs--};
        
                for(my $i=0 ; $i<$cs ; $i++)
                {
                    $cw+=$self->{-coldata}->[$c+$i]->{-avgw};
                }
                for(my $i=1 ; $i<$rs ; $i++)
                {
                    $ch-=$self->{-rowdata}->[$r+$i]->{-avgh};
                }
                
                if($cell->isReflowAble())
                {
                    $ch+=$cell->heightByWidth($cw);
                }
                else
                {
                    $ch+=$cell->height();
                }
                $ch=0 if($ch<0);
                
                #for(my $i=0 ; $i<$rs ; $i++)
                #{
                #    if($self->{-rowdata}->[$r+$i]->{-avgh} < ($ch/$rs))
                #    {
                #        $self->{-rowdata}->[$r+$i]->{-avgh}=($ch/$rs);
                #    }
                #}
                if($self->{-rowdata}->[$r+$i]->{-avgh} < $ch)
                {
                    $self->{-rowdata}->[$r+$i]->{-avgh}=$ch;
                }

                # print STDERR qq[.($r:$c): cw=$cw ch=$ch\n];
            }
        }
    }
    
    my $h=0; map { $h+=$_->{-avgh}; } @{$self->{-rowdata}};
    map { $h = $h>$_->{-avgh} ? $h : $_->{-avgh} ; } @{$self->{-coldata}};

    $h+=($self->{-paddingtop} || $self->{-padding});
    $h+=($self->{-paddingbottom} || $self->{-padding});
    $h+=($self->{-margintop} || $self->{-margin});
    $h+=($self->{-marginbottom} || $self->{-margin});
    
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

sub addRow
{
    my ($self,@cols)=@_;
    push @{$self->{-rows}},[@cols];
    if(scalar @cols >= $self->{-maxcols})
    {
        $self->{-maxcols}=scalar @cols;
    }
    $self->{-maxrows}++;
    
    $self->{-rowdata}->[$self->{-maxrows}-1]||={};
    $self->{-rowdata}->[$self->{-maxrows}-1]->{-minw}=0;
    $self->{-rowdata}->[$self->{-maxrows}-1]->{-maxw}=0;
    
    for(my $i=0 ; $i<scalar @cols ; $i++)
    {
        $self->{-coldata}->[$i]||={};
        if(defined $cols[$i] && $cols[$i]->isReflowAble())
        {
            if($self->{-coldata}->[$i]->{-minw} <= $cols[$i]->minWidth())
            {
                $self->{-coldata}->[$i]->{-minw}=$cols[$i]->minWidth();
            }
            if($self->{-rowdata}->[$self->{-maxrows}-1]->{-minh} <= $cols[$i]->minHeight())
            {
                $self->{-rowdata}->[$self->{-maxrows}-1]->{-minh}=$cols[$i]->minHeight();
            }
            
            if($self->{-coldata}->[$i]->{-maxw} <= $cols[$i]->maxWidth())
            {
                $self->{-coldata}->[$i]->{-maxw}=$cols[$i]->maxWidth();
            }
            if($self->{-rowdata}->[$self->{-maxrows}-1]->{-maxh} <= $cols[$i]->maxHeight())
            {
                $self->{-rowdata}->[$self->{-maxrows}-1]->{-maxh}=$cols[$i]->maxHeight();
            }

        }
        elsif(defined $cols[$i] && !$cols[$i]->isReflowAble())
        {
            if($self->{-coldata}->[$i]->{-minw} <= $cols[$i]->width())
            {
                $self->{-coldata}->[$i]->{-minw}=$cols[$i]->width();
            }
            if($self->{-rowdata}->[$self->{-maxrows}-1]->{-minh} <= $cols[$i]->height())
            {
                $self->{-rowdata}->[$self->{-maxrows}-1]->{-minh}=$cols[$i]->height();
            }

            if($self->{-coldata}->[$i]->{-maxw} <= $cols[$i]->width())
            {
                $self->{-coldata}->[$i]->{-maxw}=$cols[$i]->width();
            }
            if($self->{-rowdata}->[$self->{-maxrows}-1]->{-maxh} <= $cols[$i]->height())
            {
                $self->{-rowdata}->[$self->{-maxrows}-1]->{-maxh}=$cols[$i]->height();
            }
        }

        $self->{-rowdata}->[$self->{-maxrows}-1]->{-minw}+=$self->{-coldata}->[$i]->{-minw};
        $self->{-rowdata}->[$self->{-maxrows}-1]->{-maxw}+=$self->{-coldata}->[$i]->{-maxw};
    }
    
    $self->{-minh}=0; $self->{-maxh}=0; $self->{-minw}=0; $self->{-maxw}=0;

    for(my $r=0 ; $r<$self->{-maxrows}; $r++)
    {
        $self->{-minh}+=$self->{-rowdata}->[$r]->{-minh};
        $self->{-maxh}+=$self->{-rowdata}->[$r]->{-maxh};
    }

    for(my $c=0 ; $c<$self->{-maxcols}; $c++)
    {
        $self->{-minw}+=$self->{-coldata}->[$c]->{-minw};
        $self->{-maxw}+=$self->{-coldata}->[$c]->{-maxw};
    }

    $self->{-minw}+=($self->{-paddingleft} || $self->{-padding});
    $self->{-minw}+=($self->{-paddingright} || $self->{-padding});
    $self->{-minw}+=($self->{-marginleft} || $self->{-margin});
    $self->{-minw}+=($self->{-marginright} || $self->{-margin});

    $self->{-maxw}+=($self->{-paddingleft} || $self->{-padding});
    $self->{-maxw}+=($self->{-paddingright} || $self->{-padding});
    $self->{-maxw}+=($self->{-marginleft} || $self->{-margin});
    $self->{-maxw}+=($self->{-marginright} || $self->{-margin});

    $self->{-minh}+=($self->{-paddingtop} || $self->{-padding});
    $self->{-minh}+=($self->{-paddingbottom} || $self->{-padding});
    $self->{-minh}+=($self->{-margintop} || $self->{-margin});
    $self->{-minh}+=($self->{-marginbottom} || $self->{-margin});

    $self->{-maxh}+=($self->{-paddingtop} || $self->{-padding});
    $self->{-maxh}+=($self->{-paddingbottom} || $self->{-padding});
    $self->{-maxh}+=($self->{-margintop} || $self->{-margin});
    $self->{-maxh}+=($self->{-marginbottom} || $self->{-margin});

    return(undef);
}

sub _render
{
    my ($self,$pdf,$page,$gfx,$x,$y,$w,$h)=@_;
    $self->heightByWidth($w);
    
    my $ty=$y;
    my $of=[];
    for(my $r=0 ; $r<$self->{-maxrows}; $r++)
    {
        push @{$of},[];
    }
    for(my $r=0 ; $r<$self->{-maxrows}; $r++)
    {
        my $tx=$x;
        if($h<=0)
        {
            for(my $c=0 ; $c<$self->{-maxcols}; $c++)
            {
                $of->[$r]->[$c]||=$self->{-rows}->[$r]->[$c];
            }
        }
        else
        {
            for(my $c=0 ; $c<$self->{-maxcols}; $c++)
            {
                my $cell=$self->{-rows}->[$r]->[$c];
                my $ch=0; my $cw=0;
                if(ref $cell)
                {
                    my $rs=$cell->rowSpan;
                    my $cs=$cell->colSpan;
                    while($r+$rs>$self->{-maxrows}) {$rs--};
                    while($c+$cs>$self->{-maxcols}) {$cs--};
                    my $ofr=0;
                    for(my $i=0 ; $i<$cs ; $i++)
                    {
                        $cw+=$self->{-coldata}->[$c+$i]->{-avgw};
                    }
                    for(my $i=0 ; $i<$rs ; $i++)
                    {
                        $ch+=$self->{-rowdata}->[$r+$i]->{-avgh};
                        #if($ch>$h)
                        #{
                        #    $ofr=$r;
                        #    print STDERR qq[($r:$c): ch=$ch h=$h r=$i rs=$rs\n];
                        #    last;
                        #}
                    }
                    if($ch>$h)
                    {
                        #if($rs>1)
                        #{
                        #    my $ff=$cell->render($pdf,$page,$gfx,$tx,$ty,$cw,$h);
                        #    if($ff)
                        #    {
                        #        $of->[$r+1]->[$c]=$ff;
                        #        $of->[$r+1]->[$c]->{-rowspan}--;
                        #    }
                        #}
                        #else
                        #{
                            $of->[$r]->[$c]=$cell->render($pdf,$page,$gfx,$tx,$ty,$cw,$h);
                        #}
                    }
                    else
                    {
                        $cell->render($pdf,$page,$gfx,$tx,$ty,$cw,$ch);
                    }
                }
                $tx+=$self->{-coldata}->[$c]->{-avgw};
            }
        }
        $h-=$self->{-rowdata}->[$r]->{-avgh};
        $ty-=$self->{-rowdata}->[$r]->{-avgh};
    }

    while(ref $of->[0] && scalar @{$of->[0]} == 0)
    {
        shift @{$of};
    }

    if(scalar @{$of})
    {
        my $obj=$self->_new(%{$self});
        my $rows=[];
        foreach my $r (0..scalar @{$of} -1)
        {
            my $defs=0; my $spans=0;
            foreach my $c (0..scalar @{$of->[$r]} -1)
            {
                $defs++ if($of->[$r]->[$c]);
                $spans++ if($of->[$r]->[$c] && $of->[$r]->[$c]->rowSpan>1);
            }
            my @line=();
            foreach my $c (0..scalar @{$of->[$r]} -1)
            {
                if($defs==$spans && $of->[$r]->[$c] && $of->[$r]->[$c]->rowSpan>1)
                {
                    $of->[$r+1]->[$c]=$of->[$r]->[$c];
                    $of->[$r+1]->[$c]->{-rowspan}-=1;
                    @line=();
                    next;
                }
                push @line,$of->[$r]->[$c];
            }
            push @{$rows},[@line] if($defs && $defs!=$spans);
        }
        if(scalar @{$rows})
        {
            map { $obj->addRow(@{$_}) } @{$rows};
            return($obj);
        }
    }

    return(undef);
}


1;

__END__
    if(0)
    {
        for(my $r=$self->{-maxrows}-1 ; $r>=0; $r--)
        {
            my $wleft=$w;
            my $mw=0;
            for(my $c=$self->{-maxcols}-1 ; $c>=0; $c--)
            {
                my $cell=$self->{-rows}->[$r]->[$c];
                print STDERR qq[($r:$c): ];
                my $hx=0; 
                my $wx=$wleft/($c+1);
                print STDERR qq[wleft=$wleft ];
                print STDERR qq[wx(B)=$wx ];

                $wx=$self->{-coldata}->[$c]->{-minw} if($wx<$self->{-coldata}->[$c]->{-minw});
                ## $wx=$self->{-coldata}->[$c]->{-avgw} if($wx<$self->{-coldata}->[$c]->{-avgw});

                print STDERR qq[wx(I)=$wx ];

                my $hs=0; my $ws=0;
                if(ref $cell)
                {
                    my $rs=$cell->rowSpan;
                    my $cs=$cell->colSpan;
                    while($r+$rs>$self->{-maxrows}) {$rs--};
                    while($c+$cs>$self->{-maxcols}) {$cs--};
                    for(my $i=1 ; $i<$cs ; $i++)
                    {
                        $ws+=$self->{-coldata}->[$c+$i]->{-avgw};
                    }
                    for(my $i=1 ; $i<$rs ; $i++)
                    {
                        $hs+=$self->{-rowdata}->[$r+$i]->{-avgh};
                    }
                    if($cell->isReflowAble())
                    {
                        $hx=$cell->heightByWidth($wx+$ws)-$hs;
                    }
                    else
                    {
                        $hx=$cell->height()-$hs;
                    }
                    $hx=0 if($hx<0);
                }
                else
                {
                    $wx/=10;
                }

                print STDERR qq[\n   wx(F)=$wx ];
                print STDERR qq[hx(F)=$hx ];

                $self->{-coldata}->[$c]->{-avgw}=$wx
                    if($self->{-coldata}->[$c]->{-avgw}<$wx);

                $wleft-=$self->{-coldata}->[$c]->{-avgw};
                $mw+=$self->{-coldata}->[$c]->{-avgw};
                $self->{-rowdata}->[$r]->{-avgh}=$hx if($self->{-rowdata}->[$r]->{-avgh}<$hx);

                print STDERR qq[\n   aw=$self->{-coldata}->[$c]->{-avgw} ];
                print STDERR qq[ah=$self->{-rowdata}->[$r]->{-avgh} \n\n];
            }
            $fw=$w/$mw if($fw>$w/$mw);
        }
        for(my $c=0; $c<$self->{-maxcols} ; $c++)
        {
            $self->{-coldata}->[$c]->{-avgw}*=$fw;
        }

        for(my $r=$self->{-maxrows}-1 ; $r>=0; $r--)
        {
            $self->{-rowdata}->[$r]->{-avgh}=0;
            for(my $c=$self->{-maxcols}-1 ; $c>=0; $c--)
            {
                my $cell=$self->{-rows}->[$r]->[$c];
                print STDERR qq[($r:$c): ];
                my $hx=0; 
                my $wx=0;
                if(ref $cell)
                {
                    my $rs=$cell->rowSpan;
                    my $cs=$cell->colSpan;
                    while($r+$rs>$self->{-maxrows}) {$rs--};
                    while($c+$cs>$self->{-maxcols}) {$cs--};

                    for(my $i=0 ; $i<$cs ; $i++)
                    {
                        $wx+=$self->{-coldata}->[$c+$i]->{-avgw};
                    }
                    for(my $i=1 ; $i<$rs ; $i++)
                    {
                        $hx-=$self->{-rowdata}->[$r+$i]->{-avgh};
                    }

                    if($cell->isReflowAble())
                    {
                        $hx+=$cell->heightByWidth($wx);
                    }
                    else
                    {
                        $hx+=$cell->height();
                    }
                    $hx=0 if($hx<0);
                }

                $self->{-rowdata}->[$r]->{-avgh}=$hx if($self->{-rowdata}->[$r]->{-avgh}<$hx);

                print STDERR qq[wx(F)=$wx hx(F)=$hx \n];
                print STDERR qq[   aw=$self->{-coldata}->[$c]->{-avgw} ah=$self->{-rowdata}->[$r]->{-avgh} \n];
            }
            $h+=$self->{-rowdata}->[$r]->{-avgh};
            print STDERR qq[($r): ah=$self->{-rowdata}->[$r]->{-avgh}\n];
        }

        for(my $r=0 ; $r<$self->{-maxrows} ; $r++)
        {
            $self->{-rowdata}->[$r]->{-avgh}=0;
            for(my $c=0 ; $c<$self->{-maxcols} ; $c++)
            {
                my $cell=$self->{-rows}->[$r]->[$c];
                print STDERR qq[($r:$c): ];
                my $hx=0; 
                my $wx=0;
                if(ref $cell)
                {
                    my $rs=$cell->rowSpan;
                    my $cs=$cell->colSpan;
                    while($r+$rs>$self->{-maxrows}) {$rs--};
                    while($c+$cs>$self->{-maxcols}) {$cs--};

                    for(my $i=0 ; $i<$cs ; $i++)
                    {
                        $wx+=$self->{-coldata}->[$c+$i]->{-avgw};
                    }
                    for(my $i=1 ; $i<$rs ; $i++)
                    {
                        $hx-=$self->{-rowdata}->[$r+$i]->{-avgh};
                    }

                    if($cell->isReflowAble())
                    {
                        $hx+=$cell->heightByWidth($wx);
                    }
                    else
                    {
                        $hx+=$cell->height();
                    }
                    $hx=0 if($hx<0);
                }

                $self->{-rowdata}->[$r]->{-avgh}=$hx if($self->{-rowdata}->[$r]->{-avgh}<$hx);

                print STDERR qq[wx(F)=$wx hx(F)=$hx \n];
                print STDERR qq[   aw=$self->{-coldata}->[$c]->{-avgw} ah=$self->{-rowdata}->[$r]->{-avgh} \n];
            }
            $h+=$self->{-rowdata}->[$r]->{-avgh};
            print STDERR qq[($r): ah=$self->{-rowdata}->[$r]->{-avgh}\n];
        }
    }

=head1 AUTHOR

alfred reibenschuh

=head1 HISTORY

    $Log: $

=cut
