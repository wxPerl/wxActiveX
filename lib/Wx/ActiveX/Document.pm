#############################################################################
## Name:        lib/Wx/ActiveX/Document.pm
## Purpose:     Wx::ActiveX::Document (Internet Explorer Wrapper)
## Author:      Mark Dootson.
## Modified by:
## Created:     2008-04-02
## SVN-ID:      $Id:$
## Copyright:   (c) 2008 Mark Dootson.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::ActiveX::Document;
use strict;
use Wx::ActiveX::IE;
use base qw( Wx::ActiveX::IE );
use Wx qw( wxID_ANY wxDefaultPosition wxDefaultSize);
use Wx::Event qw( :activex );

our $VERSION = '0.06';

# load events

my %standardevents = (
    DOCUMENT_FRAME_CLOSING => 2,
);

for my ($eventname, $numparams) (%standardevents) {
    __PACKAGE__->wxaxperl_load_event( $eventname, $numparams );
}

#-----------------------------------
# Constructors
#-----------------------------------

sub new {
    my $class = shift;
    Wx::LogFatalError( "%s", 'Wx::ActiveX::Document parent must be a Wx::Window class' )
        if( (not exists $_[0]) || (!$_[0]->isa('Wx::Window')));
    $_[1] = wxID_ANY if not exists $_[1];
    $_[2] = wxDefaultPosition if not exists $_[2];
    $_[3] = wxDefaultSize if not exists $_[3];
    $_[4] = 0 if not exists $_[4];
    my $self = $class->SUPER::new( @_ );
    $self->{__wxad_prevent_navigation} = 0;
    EVT_ACTIVEX_IE_BEFORENAVIGATE2($self, $self, \&__wxax_on_event_beforenavigate );
    return $self;
}

sub OpenDocument {
    my ($reforobj, $parent, $document) = @_;
    Wx::LogFatalError( "%s", 'Wx::ActiveX::Document_Frame parent must be a Wx::TopLevelWindow class' )
        if( (not defined $parent) || (!$parent->isa('Wx::TopLevelWindow')));

    my $frame = Wx::ActiveX::Document::_Frame->new( $parent );
    my $doc = $frame->GetDocument();
    $doc->LoadURL( $document );
    
    return $doc;
}

sub GetTopLevelWindow {
    my $self = shift;
    my $tlw = $self;
    while( !$tlw->isa('Wx::TopLevelWindow') ) {
        $tlw = $tlw->GetParent() or last;
    }
    return $tlw;
}

sub __wxax_on_event_beforenavigate {
    my ( $self, $event ) = @_;
    $event->Veto() if $self->{__wxad_prevent_navigation};
}

package Wx::ActiveX::Document::_Frame;

use strict;
use Wx::ActiveX;
use Wx qw( :activex wxTheApp wxDEFAULT_FRAME_STYLE wxID_ANY wxDEFAULT_FRAME_STYLE);
use base qw( Wx::Frame );
use Wx::Event qw( :activex EVT_CLOSE )

our $VERSION = 0.06;

# class data
my $__wxadf_sessiondata = {};

# default size

{
    my $defsize = Wx::GetDisplaySize()->Scale(0.75, 0.75);
    my $maxW = 1024;
    my $maxH = 768;
    my $width = $defsize->GetWidth();
    my $height = $defsize->GetHeight();
    $__wxadf_sessiondata->{width} = $width > $maxW ? $maxW : $width;
    $__wxadf_sessiondata->{height} = $width > $maxW ? $maxW : $width;
    
}

sub new {
    my $class = shift;
    $__wxadf_sessiondata->{left} = exists $__wxadf_sessiondata->{left} ? $__wxadf_sessiondata->{left} : -1;
    $__wxadf_sessiondata->{top} = exists $__wxadf_sessiondata->{top} ? $__wxadf_sessiondata->{top} : -1;
    $_[0] = wxTheApp->GetTopWindow if not exists $_[0];
    $_[1] = wxID_ANY if not exists $_[1];
    $_[2] = wxTheApp->GetAppName() . ' - Document' if not exists $_[2];
    $_[3] = [ $__wxadf_sessiondata->{left} , $__wxadf_sessiondata->{top} ] if not exists $_[3];
    $_[4] = [ $__wxadf_sessiondata->{width} , $__wxadf_sessiondata->{height} ] if not exists $_[4];
    $_[5] = wxDEFAULT_FRAME_STYLE if not exists $_[5];
    my $self = $class->SUPER::new( @_ );
    
    $self->{__wxaxd_docwindow} = Wx::ActiveX::Document->new($self);
    $self->{__wxaxd_mainsizer} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{__wxaxd_mainsizer}->Add($self->{__wxaxd_docwindow}, 1, wxALL|wxEXPAND, 0);
    $self->SetSizer( $self->{__wxaxd_mainsizer} );
    $self->Centre;
    EVT_CLOSE($self, sub { shift->OnEventClose( @_ ) } );
    
    $self->Layout;
    return $self;
}

sub GetDocument {
    my $self = shift;
    return $self->{__wxaxd_docwindow};
}

sub OnEventClose {
    my ( $self, $event ) = @_;
    
    # raise a frame closing event
    my $queryclosing = Wx::NotifyEvent->new( &Wx::wxAxEVENT_ACTIVEX_DOCUMENT_FRAME_CLOSING, $self->GetId );
    $queryclosing->SetEventObject($self);
    $queryclosing->Allow;
    $self->ProcessEvent( $queryclosing );    
    $self->Skip( $notifyevent->IsAllowed ? 1 : 0 );

}



1;
