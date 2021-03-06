unit FLogin;

interface

uses System.IOUtils, IdGlobalProtocols, FMX.VirtualKeyboard, FMX.Platform, System.UITypes,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.Forms,System.SysUtils,
  FMX.ListView.Adapters.Base,  System.Notification, Data.DB,
  Data.Bind.EngExt, Fmx.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Fmx.Bind.Editors, System.Sensors, System.Sensors.Components, FMX.Dialogs,
  Data.Bind.Components, Data.Bind.DBScope, FMX.TabControl, System.Classes,
  System.Actions, FMX.ActnList, FMX.StdCtrls, FMX.Maps, FMX.Effects, System.StrUtils,
  FMX.Filter.Effects, FMX.Ani, FMX.Objects, FMX.ListView, FMX.ScrollBox,
  FMX.Memo, FMX.Edit, FMX.Controls.Presentation, FMX.Layouts, FMX.Controls,
  FMX.Types, FMX.SearchBox, FMX.ListBox, System.Types, DateUtils, FMX.MultiView, JSON,
  FMX.Graphics, Variants, IniFiles, FMX.WebBrowserHelper,

  REST.JSON,
  Rest.Types,
  REST.Client,
  REST.Response.Adapter,
  REST.Authenticator.Simple,
  REST.Authenticator.Basic,
  REST.Authenticator.OAuth

  {$IFDEF ANDROID}
    ,Androidapi.JNI.GraphicsContentViewText
    ,Androidapi.JNI.PowerManager
    ,Androidapi.JNI.Telephony
    ,Androidapi.JNI.App
    ,FMX.Platform.Android
    ,FMX.WebBrowser.Android
    ,FMX.Helpers.Android
    ,Androidapi.Helpers
    ,Androidapi.JNI.JavaTypes
    ,Androidapi.JNI.Net
    ,Androidapi.JNIBridge
    ,Androidapi.JNI.Location
    ,Androidapi.JNI.Provider
    ,Androidapi.JNI.Os
  {$ENDIF ANDROID}
  ,IdURI, FMX.WebBrowser, System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent;

 type
  TfrmLogin = class(TForm)
    TabCtrlPrincipal: TTabControl;
    TabItemLogin: TTabItem;
    Layout1: TLayout;
    ScaledLayout1: TScaledLayout;
    GridPanelLayout1: TGridPanelLayout;
    ImageControl1: TImageControl;
    StyleBook1: TStyleBook;
    VertScrollBox6: TVertScrollBox;
    WebBrowser1: TWebBrowser;
    Button7: TButton;
    GridPanelLayout2: TGridPanelLayout;
    lbLogin: TLabel;
    edtLogin: TEdit;
    ClearEditButton1: TClearEditButton;
    edtSenha: TEdit;
    ClearEditButton2: TClearEditButton;
    lbSenha: TLabel;
    btnLogin: TButton;
    btnOk: TButton;
    imgLoginFacebook: TImage;
    imgLoginGoogle: TImage; 
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormFocusChanged(Sender: TObject);
    procedure FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
    procedure imgLoginGoogleClick(Sender: TObject);
    procedure imgLoginFacebookClick(Sender: TObject);

  private
    { Private declarations }

    FKBBounds: TRectF;
    FNeedOffset: Boolean;

    {$IFDEF ANDROID}
    fWakeLock: JWakeLock;
    {$ENDIF ANDROID}

    procedure CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
    procedure RestorePosition;
    procedure UpdateKBBounds;
    procedure LoginGoogle;
    procedure LoginFaceBook;
    function OpenURL(const URL: string; const DisplayError: Boolean = False): Boolean;
  public
    function BuscarFoto(const AURL: String) : TStream;
    function BuscarFoto_HTTP(aURL: String): TStream;
  end;

var
  frmLogin: TfrmLogin;
  iTempo : Integer;

implementation

uses System.Math, FAutenticacao, uDM;

{$R *.fmx}

procedure TfrmLogin.LoginGoogle;
var
  sClientID, sClientSecret, aAuthorizationEndpoint, aAccessEndPoint,
  sScope, sRedirectionEndPoint, sURL, sChave : String;
begin
  frmAutenticacao.Memo1.Lines.Clear;
  frmAutenticacao.Image1.MultiResBitmap.Clear;

  bFacebookLogin := False;
  bGoogleLogin   := True;

  frmAutenticacao.Memo1.Visible := False;
  dm.RESTClient1.ResetToDefaults;

  sClientID     := '528992542525-fpdheitehjqd639btvn1iuqvgpf9bvkc.apps.googleusercontent.com';
  sClientSecret := '_CSljsOtroFIQscvntUPbtMq';

  aAuthorizationEndpoint := 'https://accounts.google.com/o/oauth2/auth';
  aAccessEndPoint        := 'https://accounts.google.com/o/oauth2/token';

  sScope                 := 'openid email profile';
  sRedirectionEndPoint   := 'http://localhost:9090'; // 'urn:ietf:wg:oauth:2.0:oob';

  dm.OAuth2Authenticator1.ClientID     := sClientID;
  dm.OAuth2Authenticator1.ClientSecret := sClientSecret;

  dm.OAuth2Authenticator1.AuthorizationEndpoint := TIdURI.ParamsEncode(aAuthorizationEndpoint);
  dm.OAuth2Authenticator1.AccessTokenEndpoint   := TIdURI.ParamsEncode(aAccessEndPoint);
  dm.OAuth2Authenticator1.Scope                 := TIdURI.ParamsEncode(sScope);
  dm.OAuth2Authenticator1.RedirectionEndpoint   := TIdURI.ParamsEncode(sRedirectionEndPoint);

  with frmAutenticacao do
  begin
    sURL := aAuthorizationEndPoint +
            '?client_id=' + sClientID +
            '&response_type=' + OAuth2ResponseTypeToString(DefaultOAuth2ResponseType) +

            '&redirect_uri=' + TIdURI.ParamsEncode(sRedirectionEndPoint) +
            '&scope=' + TIdURI.ParamsEncode(sScope);

    WebBrowser1.URL := sURL;
    WebBrowser1.SetUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36');
    WebBrowser1.Visible := True;

    Show;

    btnOk.Enabled := False;
    WebBrowser1.Navigate;
  end;
end;

procedure TfrmLogin.LoginFaceBook;
var
  sClientID, sClientSecret, aAuthorizationEndpoint, aAccessEndPoint,
  sScope, sRedirectionEndPoint, sURL, sChave : String;
begin
  bFacebookLogin := True;
  bGoogleLogin   := False;
  bJaMostrou     := False;

  sClientID     := '600167777046940';
  sClientSecret := '9fa426b436ed490ba32c4cc96086a861';

  frmAutenticacao.Memo1.Visible := False;
  dm.RESTClient1.ResetToDefaults;

  aAuthorizationEndpoint := 'https://www.facebook.com/v3.1/dialog/oauth';
  aAccessEndPoint        := 'https://graph.facebook.com/oauth/access_token';

  sScope                 := 'public_profile, email'; //  'email, name, first_name, last_name, picture';
  sRedirectionEndPoint   := 'https://www.facebook.com/connect/login_success.html';

  dm.OAuth2Authenticator1.ClientID     := sClientID;
  dm.OAuth2Authenticator1.ClientSecret := sClientSecret;

  dm.OAuth2Authenticator1.AuthorizationEndpoint := TIdURI.ParamsEncode(aAuthorizationEndpoint);
  dm.OAuth2Authenticator1.AccessTokenEndpoint   := TIdURI.ParamsEncode(aAccessEndPoint);
  dm.OAuth2Authenticator1.Scope                 := TIdURI.ParamsEncode(sScope);
  dm.OAuth2Authenticator1.RedirectionEndpoint   := TIdURI.ParamsEncode(sRedirectionEndPoint);

  with frmAutenticacao do
  begin
    sURL := aAuthorizationEndpoint + '?' +
            'app_id=' + sClientID + '&' +
            'response_type=token' + '&' +
            'redirect_uri=' + TIdURI.ParamsEncode(sRedirectionEndPoint);

    WebBrowser1.URL := sURL;
    WebBrowser1.Visible := True;

    Show;

    btnOk.Enabled := False;
    WebBrowser1.Navigate;
  end;
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  VertScrollBox6.OnCalcContentBounds := CalcContentBoundsProc;
end;

procedure TfrmLogin.FormFocusChanged(Sender: TObject);
begin
  UpdateKBBounds;
end;

procedure TfrmLogin.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
{$IFDEF ANDROID}
var
  FService : IFMXVirtualKeyboardService;
{$ENDIF ANDROID}
begin
  if (Key = vkHardwareBack) then
  begin
  {$IFDEF ANDROID}
    TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService,IInterface(FService));

    if (FService <> nil) and (TVirtualKeyboardState.Visible in FService.VirtualKeyboardState) then
    begin
      {Se back button for pressionado e o teclado estiver ativo... nada faz}
    end
      else
      begin
        Key:= 0;
        TabCtrlPrincipal.ActiveTab := TabItemLogin;
      end;
  {$ENDIF ANDROID}
  end;

  if (Key = vkReturn) then
  begin
    Key := vkTab;
    KeyDown(Key, KeyChar, Shift);
  end;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  {$IFDEF ANDROID}
  AcquireWakeLock(fWakeLock);
  {$ENDIF ANDROID}
end;

procedure TfrmLogin.FormVirtualKeyboardHidden(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := False;
  RestorePosition;
end;

procedure TfrmLogin.FormVirtualKeyboardShown(Sender: TObject; KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKBBounds             := TRectF.Create(Bounds);
  FKBBounds.TopLeft     := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TfrmLogin.imgLoginFacebookClick(Sender: TObject);
begin
  frmAutenticacao.Memo1.Lines.Clear;
  frmAutenticacao.Image1.MultiResBitmap.Clear;

  frmAutenticacao.Memo1.Visible  := False;
  frmAutenticacao.Image1.Visible := False;

  LoginFaceBook;
end;

procedure TfrmLogin.imgLoginGoogleClick(Sender: TObject);
begin
  frmAutenticacao.Memo1.Lines.Clear;
  frmAutenticacao.Image1.MultiResBitmap.Clear;

  frmAutenticacao.Memo1.Visible  := False;
  frmAutenticacao.Image1.Visible := False;

  LoginGoogle;
end;

procedure TfrmLogin.RestorePosition;
begin
  VertScrollBox6.ViewportPosition := PointF(VertScrollBox6.ViewportPosition.X, 0);
  ScaledLayout1.Align             := TAlignLayout.Client;
  VertScrollBox6.RealignContent;
end;

procedure TfrmLogin.UpdateKBBounds;
var
  LFocused   : TControl;
  LFocusRect : TRectF;
begin
  FNeedOffset := False;

  if Assigned(Focused) then
  begin
    LFocused   := TControl(Focused.GetObject);
    LFocusRect := LFocused.AbsoluteRect;

    LFocusRect.Offset(VertScrollBox6.ViewportPosition);

    if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) and
       (LFocusRect.Bottom > FKBBounds.Top) then
    begin
      FNeedOffset         := True;
      ScaledLayout1.Align := TAlignLayout.Horizontal;
      VertScrollBox6.RealignContent;

      Application.ProcessMessages;
      VertScrollBox6.ViewportPosition := PointF(VertScrollBox6.ViewportPosition.X, LFocusRect.Bottom - FKBBounds.Top);
    end;
  end;

  if not FNeedOffset then
  begin
    RestorePosition;
  end;
end;

procedure TfrmLogin.CalcContentBoundsProc(Sender: TObject; var ContentBounds: TRectF);
begin
  if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom, 2 * ClientHeight - FKBBounds.Top);
  end;
end;

function TfrmLogin.BuscarFoto(Const AURL : String) : TStream;
var
  oBMP  : TBitmap;
  oFoto : TStream;
begin
  Result := nil;

  oFoto :=  TStringStream.Create;

  oBMP := TBitmap.Create;

  try
    dm.RESTClientPhoto.BaseURL := AURL;
    dm.RESTRequestPhoto.Execute;

    if (dm.RESTResponsePhoto.StatusCode = 200) then
    begin
      oFoto.WriteData(dm.RESTResponsePhoto.RawBytes, dm.RESTResponsePhoto.ContentLength);
      oFoto.Seek(0, 0);

      oBMP.LoadFromStream(oFoto);
      oBMP.Assign(oBMP);
      Result := oFoto;
    end else begin
      Result := nil;
    end;
  finally
    oBMP.Free;
  end;
end;

function TfrmLogin.BuscarFoto_HTTP(aURL : String) : TStream;
var
  MS : TMemoryStream;
  Imagem : TBitMap;
  http : THTTPClient;
begin
  MS   := TMemoryStream.Create;
  http := THTTPClient.Create;

  imagem := TBitMap.Create;

  try
    try
      http.Get(aurl, MS);
    except
      on e: exception do
      begin
        ShowMessage('Erro ao carregar foto' + #13 + e.message);
      end;
    end;

    MS.Position := 0;
    Result := MS;
  finally
    imagem.free;
  end;
end;

function TfrmLogin.OpenURL(const URL: string; const DisplayError: Boolean = False): Boolean;
var
  Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW,
            TJnet_Uri.JavaClass.parse(StringToJString(URL)));

  try
    TAndroidHelper.Activity.startActivity(Intent);
    TAndroidHelper.Display.getName;
    exit(true);
  except
    on e: Exception do
    begin
      if DisplayError then ShowMessage('Erro: ' + e.Message);
      exit(false);
    end;
  end;

  FreeAndNil(Intent);
end;

end.
