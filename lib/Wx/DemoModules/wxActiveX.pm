#############################################################################
## Name:        lib/Wx/DemoModules/wxActiveX.pm
## Purpose:     wxPerl demo helper for Wx::ActiveX
## Author:      Mark Dootson
## Created:     13/11/2007
## SVN-ID:      $Id$
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

BEGIN {
    package Wx::ActiveX;
    our $__wxax_debug; # some info output
    package Wx::DemoModules::wxActiveX;
}

package Wx::DemoModules::wxActiveX;
use strict;
use Wx qw(:sizer wxTE_MULTILINE wxYES_NO wxICON_QUESTION wxCENTRE wxYES wxFD_OPEN wxFD_FILE_MUST_EXIST
           wxID_CANCEL wxTE_READONLY wxDefaultPosition wxDefaultSize wxID_ANY wxID_OK );
use Wx::Event qw( EVT_BUTTON) ;

use Wx::ActiveX qw( EVT_ACTIVEX );           
use Wx::ActiveX::Document qw( :document );
use Wx::ActiveX::IE;
use Wx::ActiveX::Mozilla;
use Wx::ActiveX::Browser qw( :browser );

use base qw(Wx::Panel);

sub add_to_tags  { qw(windows) }
sub title { 'wxActiveX' }

$Wx::ActiveX::__wxax_debug = 1;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    
    my $browser = $self->load_browser('mozilla') || $self->load_browser('IE');

    $browser->LoadUrl("http://wxperl.sf.net") ;

    my $top_s = Wx::BoxSizer->new( wxVERTICAL );
    my $but_s = Wx::BoxSizer->new( wxHORIZONTAL );
    my $but_s2 = Wx::BoxSizer->new( wxHORIZONTAL );
    
    my $LoadUrl = Wx::Button->new( $self, -1, 'LoadUrl' );
    my $LoadString = Wx::Button->new( $self, -1, 'LoadString' );
    my $GoBack = Wx::Button->new( $self, -1, 'GoBack' );
    my $GoForward = Wx::Button->new( $self, -1, 'GoForward' );
    my $GoHome = Wx::Button->new( $self, -1, 'GoHome' );
    my $GoSearch = Wx::Button->new( $self, -1, 'GoSearch' );
    my $Refresh = Wx::Button->new( $self, -1, 'Refresh' );
    my $Stop = Wx::Button->new( $self, -1, 'Stop' );
    my $GetStringSelection = Wx::Button->new( $self, -1, 'GetStringSelection' );
    my $GetText = Wx::Button->new( $self, -1, 'GetText' );
    my $GetTextHTML = Wx::Button->new( $self, -1, 'GetTextHTML' );
    my $Print = Wx::Button->new( $self, -1, 'Print' );
    my $PrintPreview = Wx::Button->new( $self, -1, 'PrintPreview' );
    my $OpenDocument = Wx::Button->new( $self, -1, 'Open Document' );
    
    my $status_txt = Wx::TextCtrl->new( $self , -1, "Browser Status", wxDefaultPosition, [200,-1] , wxTE_READONLY );
    
    $self->{STATUS} = $status_txt ;
  
    $but_s->Add( $LoadUrl );
    $but_s->Add( $LoadString );
    $but_s->Add( $GoBack );
    $but_s->Add( $GoForward );
    $but_s->Add( $GoHome );
    $but_s->Add( $Refresh );
    $but_s->Add( $Stop );
    $but_s2->Add( $GoSearch );
    $but_s2->Add( $GetStringSelection );
    $but_s2->Add( $GetText );
    $but_s2->Add( $GetTextHTML );
    $but_s2->Add( $Print );
    $but_s2->Add( $PrintPreview );
    $but_s2->Add( $OpenDocument );
  
    $top_s->Add( $browser, 1, wxGROW|wxALL, 5 );
    $top_s->Add( $status_txt , 0, wxGROW|wxALL, 0);
    $top_s->Add( $but_s, 0, wxALL, 5 );
    $top_s->Add( $but_s2, 0, wxALL, 5 );
  
    $self->SetSizer( $top_s );
    $self->SetAutoLayout( 1 );
  
    EVT_BUTTON( $self, $LoadUrl, \&OnLoadUrl );
    EVT_BUTTON( $self, $LoadString, \&OnLoadString );
    EVT_BUTTON( $self, $GoBack, \&OnGoBack );
    EVT_BUTTON( $self, $GoForward, \&OnGoForward );
    EVT_BUTTON( $self, $GoHome, \&OnGoHome );
    EVT_BUTTON( $self, $GoSearch, \&OnGoSearch );
    EVT_BUTTON( $self, $Refresh, \&OnRefresh );
    EVT_BUTTON( $self, $Stop, \&OnStop );
    EVT_BUTTON( $self, $GetStringSelection, \&OnGetStringSelection );
    EVT_BUTTON( $self, $GetText, \&OnGetText );
    EVT_BUTTON( $self, $GetTextHTML, \&OnGetTextHTML );
    EVT_BUTTON( $self, $Print, \&OnPrint );
    EVT_BUTTON( $self, $PrintPreview, \&OnPrintPreview );
    EVT_BUTTON( $self, $OpenDocument, \&OnOpenDocument );

    # get parent frame for Wx::ActiveX::Document
    my $parent = $self;
    while( !$parent->isa('Wx::TopLevelWindow') ) {
        $parent = $parent->GetParent or last;
    }
    if(!$parent) {
        Wx::LogError("%s", 'Unable to find parent Wx::Frame for Wx::ActiveX::Document');
        return;
    }
    
    EVT_ACTIVEX_DOCUMENT_FRAME_CLOSING($parent, \&OnDocumentFrameClosing);
    
    return $self;
}

sub load_browser {
    my ($self, $type) = @_;
    
    my $browserclass = ( $type eq 'IE' ) ? 'Wx::ActiveX::UE' : 'Wx::ActiveX::Mozilla';
    
    if($self->{browser}) {
        $self->{browser}->Close;
        $self->{browser}->Destroy;
        $self->{browser} = undef;
    }
    
    my $browser = $browserclass->new( $self , wxID_ANY, wxDefaultPosition, wxDefaultSize );
    
    return if(!$browser);
    
    EVT_ACTIVEX_BROWSER_NAVIGATECOMPLETE2($self, $browser, sub{
        my ( $obj , $evt ) = @_ ;
        my $url = $evt->{URL} ;
        Wx::LogStatus( "ACTIVEX_BROWSER NavigateComplete2 >> $url" );
    } );
   
    EVT_ACTIVEX($self, $browser, "BeforeNavigate2", sub{
        my ( $obj , $evt ) = @_ ;
        my $url = $evt->{URL} ;
        Wx::LogStatus( "ACTIVEX BeforeNavigate2 >> $url" );
    } );
    
    EVT_ACTIVEX_BROWSER_NEWWINDOW2($self, $browser, sub{
        my ( $obj , $evt ) = @_ ;  
        $evt->Veto ;
        Wx::LogStatus( "ACTIVEX_BROWSER NewWindow2 >> **Vetoed**" );
    }) ;
    
    EVT_ACTIVEX_BROWSER_STATUSTEXTCHANGE($self, $browser, sub{
        my ( $obj , $evt ) = @_ ;
        my $status = $self->{STATUS} ;
        $status->SetValue($evt->{Text});
    });
    
    $self->{browser} = $self->{IE} =  $self->{mozilla} = $browser;
    return $browser;
}

sub Query {
  my ( $self, $text_init , $width , $height , $multy) = @_ ;
  
  $width = 200 if (defined($width) && ($width < 20)) ;
  $height = -1 if (defined($height) && ($height < 1)) ;
  
  $width ||= 200;
  $height ||= -1;
  
  my $dialog = Wx::Dialog->new($self , -1 , "Query" , wxDefaultPosition, wxDefaultSize,) ;
  my $sizer = Wx::BoxSizer->new( wxHORIZONTAL );
  
  my $txt_flag = 0;
  if ( $multy ) { $txt_flag = $txt_flag|wxTE_MULTILINE ;}
  
  my $txt = Wx::TextCtrl->new( $dialog , -1 , $text_init , wxDefaultPosition , [$width,$height] , $txt_flag ) ;
  my $ok = Wx::Button->new($dialog, wxID_OK , 'OK');

  $sizer->Add( $txt );
  $sizer->Add( $ok ) ;
  
  $dialog->SetSizer( $sizer );
  $dialog->SetAutoLayout( 1 );  
  
  $sizer->Fit( $dialog );
  $sizer->SetSizeHints( $dialog );
  
  $dialog->ShowModal() ;
  
  my $val = $txt->GetValue() ;
  
  $dialog->Destroy() ;

  return( $val ) ;
}

sub OnPrint {
  my ($self, $event) = @_ ;
  $self->{IE}->Print(1) ;
}

sub OnPrintPreview {
  my ($self, $event) = @_ ;
  $self->{IE}->PrintPreview ;
}

sub OnLoadUrl {
  my ($self, $event) = @_ ;
  my $url = $self->Query("http://wxperl.sf.net") ;
  $self->{IE}->LoadUrl($url) ;
}

sub OnLoadString {
  my ($self, $event) = @_ ;
  my $html = $self->Query(q`<html>
<body bgcolor="#FFFFFF">
  <center><b>wxIE Test</b></center>
</body>
</html>
`,400,300,1) ;
  $self->{IE}->LoadString($html) ;

}

sub OnGoBack {
  my ($self, $event) = @_ ;
  $self->{IE}->GoBack() ;

}

sub OnGoForward {
  my ($self, $event) = @_ ;
  $self->{IE}->GoForward() ;

}

sub OnGoHome {
  my ($self, $event) = @_ ;
  $self->{IE}->GoHome() ;

}

sub OnGoSearch {
  my ($self, $event) = @_ ;
  $self->{IE}->GoSearch() ;

}

sub OnRefresh {
  my ($self, $event) = @_ ;
  $self->{IE}->Refresh() ;

}

sub OnStop {
  my ($self, $event) = @_ ;
  $self->{IE}->Stop() ;

}

sub OnGetStringSelection {
  my ($self, $event) = @_ ;
  my $val = $self->{IE}->GetStringSelection() ;
  Wx::LogMessage( "GetStringSelection: $val" );
}

sub OnGetText {
  my ($self, $event) = @_ ;
  my $val = $self->{IE}->GetText() ;
  my $html = $self->Query($val,400,300,1) ;
}

sub OnGetTextHTML {
  my ($self, $event) = @_ ;
  my $val = $self->{IE}->GetText(1) ;
  my $html = $self->Query($val,400,300,1) ;
}

sub OnOpenDocument {
    my ($self, $event) = @_ ;
    
    my $prompt = 'Please select a document to load';

    my $style = wxFD_OPEN|wxFD_FILE_MUST_EXIST;
    
    my $defaultpath = '';
    my $priorfile = '';
    my $filemask = 'All Files (*.*)|*.*';
    
    my $parent = $self;
    while( !$parent->isa('Wx::TopLevelWindow') ) {
        $parent = $parent->GetParent or last;
    }
    if(!$parent) {
        Wx::LogError("%s", 'Unable to find parent Wx::Frame for Wx::ActiveX::Document');
        return;
    }
    
    my $dialog = Wx::FileDialog->new
        (
            $parent,
            $prompt,
            $defaultpath,
            $priorfile,
            $filemask,
            $style
        );
        
    my $filepath = '';

    if( $dialog->ShowModal == wxID_CANCEL ) {
        $filepath = '';
    } else {
        $filepath = $dialog->GetPath();
    }
    return if(!$filepath );
    
    my $document = Wx::ActiveX::Document->OpenDocument($parent, $filepath);
    $document->AllowNavigate(0);
    
}

sub OnDocumentFrameClosing {
    my ($parentwindow, $event) = @_ ;
    $event->Veto  if( ! question_message('Are you sure you wish to close the document frame?') );    
    $event->Skip(0);
}

sub question_message {
    my $msg = shift;
    my $title = 'Wx::ActiveX - Wx::Demo - Module';
    if(Wx::MessageBox($msg,
                   $title, 
                   wxYES_NO|wxICON_QUESTION|wxCENTRE, undef) == wxYES) {
        return 1;
    } else {
        return 0;
    }
}

1;
