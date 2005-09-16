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

package PDF::APIx::Layout::MarkupText;

BEGIN 
{
    use utf8;
    use Encode qw(:all);
    use POSIX qw[ floor ceil ];
    use XML::Parser;

    use PDF::API2::UniWrap;
    use PDF::APIx::Layout::RawTextObjects;

    use vars qw( @ISA $VERSION );

    @ISA=qw[ PDF::APIx::Layout::RawTextObjects ];

    ($VERSION) = '$Revision: $' =~ /Revision: (\S+)\s/; # $Date: $
}

no warnings qw[ deprecated recursion uninitialized ];

sub _tm_calc_style_fallback
{
    my @style_prelookup=@_;
    my %style_fallback=(
        'oblique'    => [qw{ italic normal regular }],
        'italic'     => [qw{ oblique normal regular }],
        'normal'     => [qw{ regular }],
        'regular'    => [qw{ normal }],
    );

    my @style_lookup=();
    my %reg=();
    my $w;
    while($w = lc shift @style_prelookup)
    {
        unless(defined $reg{$w})
        {
            push @style_lookup, $w;
            push @style_prelookup, @{$style_fallback{$w}} if(defined $style_fallback{$w});
            $reg{$w}=1;
        }
    }
    
    return(@style_lookup);
}
sub _tm_calc_weight_fallback
{
    my @weight_prelookup=@_;
    my %weight_fallback=(
        'thin'       => [qw{ ultralight extralight light normal regular }],
        'ultralight' => [qw{ extralight light normal regular }],
        'extralight' => [qw{ light normal regular }],
        'light'      => [qw{ normal regular }],
        'normal'     => [qw{ regular }],
        'medium'     => [qw{ demibold semibold bold }],
        'demibold'   => [qw{ semibold bold }],
        'semibold'   => [qw{ bold }],
        'heavy'      => [qw{ extrabold ultrabold bold }],
        'extrabold'  => [qw{ ultrabold bold }],
        'ultrabold'  => [qw{ bold }],
    );

    my @weight_lookup=();
    my %reg=();
    my $w;
    while($w = lc shift @weight_prelookup)
    {
        unless(defined $reg{$w})
        {
            push @weight_lookup, $w;
            push @weight_prelookup, @{$weight_fallback{$w}} if(defined $weight_fallback{$w});
            $reg{$w}=1;
        }
    }
    
    return(@weight_lookup);
}
sub _tm_calc_stretch
{
    my $s = shift @_;
    my %stretch=qw[
        ultracondensed  0.500
        extracondensed  0.625
        condensed       0.750
        semicondensed   0.875
        normal          1
        medium          1
        semiexpanded    1.125
        expanded        1.250
        extraexpanded   1.500
        ultraexpanded   2
    ];
    return($s) if($s=~m|^[\d\.]+$|);
    return($stretch{$s}) if(defined $stretch{$s});
    return(1);
}
sub _tm_calc_size
{
    my $s = shift @_;
    my %size=qw[
        xx-small     6
        x-small      8
        small       10
        medium      12
        normal      12
        large       14
        x-large     18
        xx-large    24
    ];
    return($s) if($s=~m|^[\d\.]+$|);
    return($size{$s}) if(defined $size{$s});
    return(10);
}
sub _tm_calc_rise
{
    my ($s,$sz)=@_;
    my %rise=qw[
        superscript 0.5
        subscript   -0.35
        none        0
    ];
    return($s) if($s=~m|^[\-\d\.]+$|);
    return($rise{$s}*$sz) if(defined $rise{$s});
    return(0);
}

#----------------------------------
# register font for face/weight/style
sub _tm_register_face
{
    my ($self,$font,$face,$weight,$style)=@_;
    $face=lc($face);
    $face=~s|[^a-z0-9]+||go;
    $weight=lc($weight);
    $weight=~s|[^a-z0-9]+||go;
    $style=lc($style);
    $style=~s|[^a-z0-9]+||go;
    if($face eq 'default')
    {
        $self->{-fonts}->{$face}=$font;
    }
    else
    {
        $self->{-fonts}->{"$face:$weight:$style"}=$font;
    }
}

#----------------------------------
# looking up the spec. face/weight/style or
# falling back to face-only
sub _tm_lookup_face
{
    my ($self,$face,$weight,$style)=@_;
    $face=lc($face);
    $face=~s|[^a-z0-9]+||go;
    $weight=lc($weight);
    $weight=~s|[^a-z0-9]+||go;
    $style=lc($style);
    $style=~s|[^a-z0-9]+||go;
    return $self->{-fonts}->{"$face:$weight:$style"} 
        if(defined $self->{-fonts}->{"$face:$weight:$style"});
    return $self->{-fonts}->{$face} 
        if(defined $self->{-fonts}->{$face});
#    return $self->{-fonts}->{default} 
#        if(defined $self->{-fonts}->{default});
    return(undef);
}

#----------------------------------
# lookup the spec. font or falling back to the default
sub _tm_lookup_font
{
    my ($self,$face,$weight,$style)=@_;
    my $font=undef;
    foreach my $weightlookup (_tm_calc_weight_fallback(lc $weight))
    {
        foreach my $stylelookup (_tm_calc_style_fallback(lc $style))
        {
            $font=$self->_tm_lookup_face($face,$weightlookup,$stylelookup);
            last if(defined $font);
        }
        last if(defined $font);
    }
    $font=$self->_tm_lookup_face('default') unless(defined $font);
    return($font);
}
sub _tm_push_span
{
    my ($xp,$span)=@_;
    push @{$xp->{-pdf}->{content}},$span;
}
sub _tm_push_content
{
    my ($xp,$str)=@_;
    $xp->{-pdf}->{content}->[-1]->[-1].=$str;
}
sub _tm_push
{
    my ($xp,%state)=@_;
    push @{$xp->{-pdf}->{stack}},{%state};
}
sub _tm_pop
{
    my ($xp)=@_;
    return(%{pop @{$xp->{-pdf}->{stack}}});
}
sub _tm_peek
{
    my ($xp)=@_;
    return(%{$xp->{-pdf}->{stack}->[-1]});
}
sub _tm_init
{
    my ($xp)=@_;
    #print STDERR "INIT.\n";
}
sub _tm_final
{
    my ($xp)=@_;
    #print STDERR "FINAL.\n";
}
sub _tm_startelement
{
    my ($xp,$element,%attr)=@_;
    #print STDERR "START: $element\n";
    my %state=_tm_peek($xp);
    if($element eq 'span' || $element eq 'p')
    {
        %state=(%state,%attr);
    }
    elsif($element eq 'b')
    {
        $state{weight}='bold';
    }
    elsif($element eq 'i')
    {
        $state{style}='italic';
    }
    elsif($element eq 'sub')
    {
        $state{rise}=(-$attr{value})||'subscript';
        $state{risesize}=$attr{size}||'normal';
    }
    elsif($element eq 'sup')
    {
        $state{rise}=$attr{value}||'superscript';
        $state{risesize}=$attr{size}||'normal';
    }
    elsif($element eq 'u')
    {
        $state{underline}=$attr{type}||'single';
    }
    elsif($element eq 'c')
    {
        $state{stretch}=$attr{value}||'condensed';
    }
    elsif($element eq 'e')
    {
        $state{stretch}=$attr{value}||'expanded';
    }
    elsif($element eq 'a')
    {
        if(defined $attr{id})
        {
            $state{id}=$attr{id};    
        }
        if(defined $attr{name})
        {
            $state{id}=$attr{name};    
        }
        if(defined $attr{href})
        {
            $state{href}=$attr{href};    
        }
    }
    _tm_push($xp,%state);
    _tm_push_span($xp,[{%state},'']);
}
sub _tm_endelement
{
    my ($xp,$element)=@_;
    #print STDERR "END: $element\n";
    _tm_pop($xp);
    my %state=_tm_peek($xp);
    _tm_push_span($xp,[{%state},'']);
}
sub _tm_char
{
    my ($xp,$str)=@_;
    _tm_push_content($xp,$str);
    #print STDERR 'DEBUG: '.Dumper($xp);
    #print STDERR "CHAR: '$str'\n";
}
sub _tm_debug
{
    #print STDERR 'DEBUG: '.Dumper(\@_);
    return('unknown');
}
sub _tm_null
{
    #print STDERR "NULL.\n";
    return('unknown');
}
# <p>
#       x=          <n>
#       y=          <n>
#       width=      <n>
#       height=     <n>
#       bgcolor=    #00FF00 
#                   | <name>
#
# <i> <b> <u> <s> <c> <e> <sub> <sup> <br/>
#
# <span> 
#       face=       serif
#                   | sans
#                   | mono
#                   | <s>
#                       | Courier 
#                       | Georgia 
#                       | Helvetica 
#                       | Times 
#                       | Trebuchet 
#                       | Verdana 
#
#       size=       xx-small            (6pt)
#                   | x-small           (8pt)
#                   | small             (10pt)
#                   | medium            (12pt)
#                   | normal            (12pt)
#                   | large             (14pt)
#                   | x-large           (18pt)
#                   | xx-large          (24pt)
#                   | <n>
#
#       style=      normal
#                   | regular
#                   | italic
#                   | oblique
#
#       weight=     thin                (100)
#                   | ultralight        (200)
#                   | extralight        (200)
#                   | light             (300)
#                   | normal            (400)
#                   | regular           (400)
#                   | medium            (500)
#                   | demibold          (600)
#                   | semibold          (600)
#                   | bold              (700)
#                   | ultrabold         (800)
#                   | extrabold         (800)
#                   | heavy             (900)
#                   | <n>
#  
#
#       stretch=    ultracondensed      (0.500)
#                   | extracondensed    (0.625) 
#                   | condensed         (0.750)
#                   | semicondensed     (0.875)
#                   | normal            (1.000)
#                   | medium            (1.000)
#                   | semiexpanded      (1.125)
#                   | expanded          (1.250)
#                   | extraexpanded     (1.500)
#                   | ultraexpanded     (2.000)
#                   | <n>
#
#       color=      #00FF00 
#                   | <name>
#
#       underline=  single 
#                   | double 
#                   | low 
#                   | none
#
#       rise=       superscript
#                   | subscript
#                   | none
#                   | <n>
#
#
#   <a> 
#       id="somename" name="somename"   %% create a "#somename" in the name-tree 
#
#       href="url"                      %% if url == m|^#| dest to name-tree 
#
sub _markup_to_objects 
{
    my ($self,$xml,%opts)=@_;
    
    if(defined $opts{-fontreg})
    {
        foreach my $reg (@{$opts{-fontreg}})
        {
            $self->_tm_register_face(@{$reg});
        }
    }
    
    my $xp=new XML::Parser::Expat(ProtocolEncoding=>'UTF-8',NoExpand=>0,NoLWP=>1);
    $xp->setHandlers(
        #'Init'         => \&_tm_init,
        #'Final'        => \&_tm_final,
        'Start'        => \&_tm_startelement,
        'End'          => \&_tm_endelement,
        'Char'         => \&_tm_char,
        'Proc'         => \&_tm_null,
        'Comment'      => \&_tm_null,
        'CdataStart'   => \&_tm_null,
        'CdataEnd'     => \&_tm_null,
        'Default'      => \&_tm_null,
        'Unparsed'     => \&_tm_null,
        'Notation'     => \&_tm_null,
        'ExternEnt'    => \&_tm_null,
        'ExternEntFin' => \&_tm_null,
        'Entity'       => \&_tm_null,
        'Doctype'      => \&_tm_null,
        'DoctypeFin'   => \&_tm_null,
        'XMLDecl'      => \&_tm_null,
    );
    $xml=PDF::API2::Util->xmlMarkupDecl."\n".$xml;
    $xp->{-pdf}={
        'fonts'=>{},
        'stack'=>[
            { 
                'face'=>'times', 
                'size'=>'normal', 
                'style'=>'normal', 
                'weight'=>'normal',
                'stretch'=>'normal',
                'color'=>'black',
                'underline'=>'none',
                'rise'=>'none',
            }
        ], 
        'content'=>[], 
    };
    $xp->parse($xml);
    my $fo=[];
    while(scalar @{$xp->{-pdf}->{content}} > 0)
    {
        my $chunk=shift @{$xp->{-pdf}->{content}};
        next if($chunk->[1] eq '');

        $chunk->[0]->{-font}=$self->_tm_lookup_font($chunk->[0]->{face},$chunk->[0]->{weight},$chunk->[0]->{style});
        $chunk->[0]->{-fontsize}=_tm_calc_size($chunk->[0]->{size});
        $chunk->[0]->{-hspace}=_tm_calc_stretch($chunk->[0]->{stretch})*100;
        $chunk->[0]->{-rise}=_tm_calc_rise($chunk->[0]->{rise},$chunk->[0]->{-fontsize});
        $chunk->[0]->{-textcolor}=[$chunk->[0]->{color}];
        $chunk->[0]->{-fontsize}=_tm_calc_size($chunk->[0]->{risesize}) if(defined $chunk->[0]->{risesize});

        delete $chunk->[0]->{face};
        delete $chunk->[0]->{weight};
        delete $chunk->[0]->{style};
        delete $chunk->[0]->{size};
        delete $chunk->[0]->{stretch};
        delete $chunk->[0]->{color};

        $chunk->[0]->{-id}=$chunk->[0]->{id};
        $chunk->[0]->{-href}=$chunk->[0]->{href};
        $chunk->[0]->{-underline}=$chunk->[0]->{underline};

        delete $chunk->[0]->{id};
        delete $chunk->[0]->{href};
        delete $chunk->[0]->{underline};

        my $wrap=PDF::API2::UniWrap->new(line_length=>1,emergency_break=>100);
        foreach my $t ( $wrap->break_lines($chunk->[1]) )
        {
            utf8::upgrade($t);
            push @{$fo},[$chunk->[0],{},$t];
        }
    }
    
    return($fo);
}

sub new
{
    my ($class,$xml,%opts)=@_;
    
    $class=ref($class) ? ref($class) : $class;
    
    my $self=$class->SUPER::_new(%opts);
    my $fo=$self->_markup_to_objects($xml,%opts);
    $self->_proc_objects($fo);

    return($self);
}

1;

__END__

=head1 AUTHOR

alfred reibenschuh

=head1 HISTORY

    $Log: $

=cut
