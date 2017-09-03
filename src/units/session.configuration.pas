{
  Stimulus Control
  Copyright (C) 2014-2017 Carlos Rafael Fernandes Picanço, Universidade Federal do Pará.

  The present file is distributed under the terms of the GNU General Public License (GPL v3.0).

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
}
unit Session.Configuration;

{$mode objfpc}{$H+}

interface

uses Classes, ComCtrls, SysUtils,  Dialogs, Forms
    {$IFNDEF NO_LIBZMQ}
    , Pupil.Client
    {$ENDIF}
    , countermanager
    ;

type

  { TDataProcedure }
  TDataProcedure = procedure (S : string) of object;

  { TGlobalContainer }

  TGlobalContainer = class //(TObject)
    {$IFNDEF NO_LIBZMQ}
    PupilClient: TPupilClient;
    {$ENDIF}
    PupilEnabled : Boolean;
    CounterManager : TCounterManager;
    RootData: string;
    RootMedia: string;
    ExeName : string;
    TimeStart : Extended;
    TestMode : Boolean;
    MonitorToShow : Byte;
  end;

  TCfgTrial = record
    Id : integer;
    Name: string;
    Kind: string;
    NumComp: integer;
    SList: TStringList;
  end;

  TVetCfgTrial = array of TCfgTrial;

  TCfgBlc = record
    ID : integer;
    Name: string;
    ITI: Integer;
    BkGnd: Integer;
    Counter : string;
    NumTrials: Integer;
    VirtualTrialValue: Integer;

    MaxCorrection: Integer;
    MaxBlcRepetition: Integer;

    DefNextBlc: string;

    CrtConsecutiveHit: Integer;
    CrtHitPorcentage : Integer;
    CrtConsecutiveMiss : Integer;
    CrtMaxTrials : Integer;
    CrtKCsqHit : Integer;
    Trials: TVetCfgTrial;
    NextBlocOnCriteria : integer;
    NextBlocOnNotCriteria : integer;
    //VetCrtBlc: array of TCrtBlc;
  end;

  TVetCfgBlc = array of TCfgBlc;

  TCoordenates = record
    Index  : Integer;
    Top    : Integer;
    Left   : Integer;
    Width  : Integer;
    Height : Integer;
  end;

  { TCfgSes }

  TCfgSes = class(TComponent)
  private
    FFilename: string;
    FGlobalContainer : TGlobalContainer;

    // todo: refactoring
    FData: string;
    FMedia: string;
    FLoaded : Boolean;
    FEditMode : Boolean;

    // session only
    FSessionName: string;
    FSessionSubject : string;
    FSessionType : string;
    FSessionServer : string;
    function GetCfgBlc(Ind: Integer): TCfgBlc;
    function GetCurrentBlc: TCfgBlc;
    function GetPupilEnabled: Boolean;
    procedure SetPupilEnabled(AValue: Boolean);
  protected
    FCol: integer;
    FRow: integer;
    FNumBlc: Integer; // Number of blocs in a session
    FBlcs: TVetCfgBlc; // blocs in session
    FNumPos: Integer; // Number of positions were stimuli will be presented
    FPositions : array of TCoordenates; // positions were stimuli will be presented
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function LoadFromFile(AFileName: string; AEditMode : Boolean): Boolean;
    function LoadTreeFromFile(FileName:string; aTree : TTreeView):Boolean;
    procedure SetLengthVetBlc;
    procedure SetLengthVetTrial(Blc : Integer);
    property EditMode : Boolean read FEditMode;
  public
    property GlobalContainer : TGlobalContainer read FGlobalContainer;
    property PupilEnabled : Boolean read GetPupilEnabled write SetPupilEnabled;
    property SessionName : string read FSessionName write FSessionName;
    property SessionSubject : string read FSessionSubject write FSessionSubject;
    property SessionType : string read FSessionType write FSessionType;
    property SessionServer : string read FSessionServer write FSessionServer;
    property Filename : string read FFilename;
  public
    property CurrentBlc : TCfgBlc read GetCurrentBlc; // helper
    property Blcs : TVetCfgBlc read FBlcs write FBlcs;
    property Blc[I: Integer]: TCfgBlc read GetCfgBlc;
    property IsLoaded : Boolean read FLoaded write FLoaded;
    property NumBlc: Integer read FNumBlc write FNumBlc;
    property NumPos: Integer read FNumPos write FNumPos;
  public
    property Data : string read FData write FData;
    property Media: string read FMedia write FMedia;
    property Col : integer read FCol write FCol;
    property Row : integer read FRow write FRow;
  end;

implementation

uses constants, Session.ConfigurationFile, Session.Configuration.GlobalContainer;

{ TCfgSes }

function TCfgSes.GetCfgBlc(Ind: Integer): TCfgBlc;
begin
  Result:= FBlcs[Ind];
end;

function TCfgSes.GetCurrentBlc: TCfgBlc;
begin
  Result := GetCfgBlc(FGlobalContainer.CounterManager.CurrentBlc);
end;

function TCfgSes.GetPupilEnabled: Boolean;
begin
  Result := FGlobalContainer.PupilEnabled;
end;

procedure TCfgSes.SetPupilEnabled(AValue: Boolean);
begin
  if FGlobalContainer.PupilEnabled=AValue then Exit;
  FGlobalContainer.PupilEnabled:=AValue;
end;

constructor TCfgSes.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGlobalContainer:= TGlobalContainer.Create;
  GGlobalContainer := FGlobalContainer;
  FLoaded := False;
end;

destructor TCfgSes.Destroy;
var i, j : Integer;
begin
  FGlobalContainer.Free;
  if Length(FBlcs) > 0 then
    for i:= Low(FBlcs) to High(FBlcs) do
      if Length(FBlcs[i].Trials) > 0 then
        for j:= Low(FBlcs[i].Trials) to High(FBlcs[i].Trials) do
           FBlcs[i].Trials[j].SList.Free;

  inherited Destroy;
end;

procedure TCfgSes.SetLengthVetBlc;
begin
  SetLength(FBlcs, FNumBlc);
end;

procedure TCfgSes.SetLengthVetTrial(Blc: Integer);
var i : integer;
begin
  SetLength(FBlcs[Blc].Trials, FBlcs[Blc].NumTrials);
  for i := 0 to FBlcs[blc].NumTrials - 1 do
    begin
      if not Assigned(FBlcs[blc].Trials[i].SList)then
        begin
          FBlcs[blc].Trials[i].SList:= TStringList.Create;
          FBlcs[blc].Trials[i].SList.Sorted := False;
          FBlcs[blc].Trials[i].SList.Duplicates := dupIgnore;
          FBlcs[blc].Trials[i].SList.BeginUpdate;
          FBlcs[blc].Trials[i].SList.Add('new=true');
          FBlcs[blc].Trials[i].SList.EndUpdate;
        end;
    end;
end;

function TCfgSes.LoadFromFile(AFileName: string; AEditMode: Boolean): Boolean;
var
  i, j : Integer;
  s1: string;
  LIniFile: TConfigurationFile;

  procedure HandleRootPath(var APath : string);
  begin
    while Pos(PathDelim, s1) <> 0 do Delete(s1, 1, Pos(PathDelim, s1));
    APath:= ExtractFilePath(AFileName) + s1;
    if not (APath[Length(APath)] = PathDelim) then APath:= APath + PathDelim;
  end;

  function DefaultMediaPath: string;
  begin
    Result := ConcatPaths([ExtractFilePath(FGlobalContainer.ExeName), 'media']);
    Result := IncludeTrailingPathDelimiter(Result);
  end;

begin
  Result := False;
  if FileExists(AFileName) then
    begin
      FEditMode := AEditMode;
      FFilename := AFileName;
      LIniFile:= TConfigurationFile.Create(AFileName);
      try
        with LIniFile do
          if SectionExists(_Main) and ValueExists(_Main, _Name) and ValueExists(_Main, _NumBlc) then
            begin
              FSessionName := ReadString(_Main, _Name, rsDefName);
              FSessionSubject := ReadString(_Main, _Subject, rsDefSubject);
              FSessionType := ReadString(_Main, _Type, T_CIC);
              FNumBlc := ReadInteger(_Main, _NumBlc, 0);
              FSessionServer := ReadString(_Main,_ServerAddress, rsDefAddress);

              // set media and data paths
              s1 := ReadString(_Main, _RootMedia, '');
              HandleRootPath(FGlobalContainer.RootMedia);
              if not DirectoryExists(FGlobalContainer.RootMedia) then
                 FGlobalContainer.RootMedia := DefaultMediaPath;

              s1 := ReadString(_Main, _RootData, '');
              HandleRootPath(FGlobalContainer.RootData);

              SetLength(FBlcs, FNumBlc);
              for i:= Low(FBlcs) to High(FBlcs) do
                begin
                  FBlcs[i] := Bloc[i+1];
                  SetLength(FBlcs[i].Trials, FBlcs[i].NumTrials);
                  for j:= Low(FBlcs[i].Trials) to High(FBlcs[i].Trials) do
                    FBlcs[i].Trials[j] := Trial[i+1,j+1];
                end;

              FLoaded := True;
              Result:= True;
            end;
      finally
        LIniFile.Free;
      end;
    end;
end;

function TCfgSes.LoadTreeFromFile(FileName: string; aTree: TTreeView): Boolean;
//from INI like files,  encoded as UTF-8 without BOM (Ansi as UTF-8)
//this functionality is not finished yet
{TODO -oRafael -cFunctionality: Load Config File From Tree List View Component}
var

  i1, i2, i3, aNumBlc, aNumTrials, aNumComp : Integer;
  ANode : TTreeNode;
  CurrStr, aux: string;
  LIniFile : TConfigurationFile;
begin
  Result:= False;
  if FileExists(FileName) then
    begin
      LIniFile:= TConfigurationFile.Create(FileName);
      aTree.BeginUpdate;
      with LIniFile do
        try
          if  SectionExists(_Main) and
              ValueExists(_Main, _Name) and
              ValueExists(_Main, _NumBlc) then
            begin
              aTree.Items.Clear;
              CurrStr := messRoot;
              ANode := aTree.Items.AddChild(nil, CurrStr);   //Level 0

              CurrStr := ReadString(_Main, _Name, messLevel_01);
              ANode := aTree.Items.AddChild(ANode, CurrStr); //Level 1

              aNumBlc := ReadInteger(_Main, _NumBlc, 0);
              for i1 := 0 to aNumBlc - 1 do
                begin
                  aux := _Blc + #32 + IntToStr(i1 + 1);
                  CurrStr :=  ReadString(aux, _Name, aux);
                  while ANode.Level > 1 do ANode := ANode.Parent; //Level 2
                  ANode := aTree.Items.AddChild(ANode, CurrStr);

                  aux:= ReadString(_Blc + #32 + IntToStr(i1 + 1), _NumTrials, '0 0');
                  aNumTrials:= StrToIntDef(Copy(aux, 0, pos(' ', aux)-1), 0);
                  for i2 := 0 to aNumTrials -1 do
                    begin
                       aux := _Blc + #32 + IntToStr(i1 + 1) + ' - ' + _Trial + IntToStr(i2 + 1);
                       CurrStr := ReadString(aux,_Name, aux);
                       while ANode.Level > 2 do ANode := ANode.Parent; //Level 3
                           ANode := aTree.Items.AddChild(ANode, CurrStr);

                       if ReadString(aux,_Kind, T_NONE) = T_Simple then
                          begin
                            aNumComp := ReadInteger(_Blc + #32 + IntToStr(i1 + 1) + ' - ' + _Trial + IntToStr(i2 + 1), _NumComp, 0);
                            for i3 := 0 to aNumComp -1 do
                              begin
                                CurrStr:= ReadString(aux,_Comp + IntToStr(i3 + 1) + _cStm,_Comp + IntToStr(i3 + 1) + _cStm);
                                while ANode.Level > 3 do ANode := ANode.Parent;
                                ANode := aTree.Items.AddChild(ANode,CurrStr); //Level 4
                              end;
                          end
                        else if ReadString(aux,_Kind, T_NONE) = T_MTS then
                          begin
                            aNumComp := ReadInteger(_Blc + #32 + IntToStr(i1 + 1) + ' - ' + _Trial + IntToStr(i2 + 1), _NumComp, 0);
                            for i3 := 0 to aNumComp do
                              begin
                                if i3 = 0 then
                                  begin
                                    CurrStr:= ReadString(aux,_Samp + _cStm, _Samp + _cStm);
                                    while ANode.Level > 3 do ANode := ANode.Parent;  //Level 4
                                    ANode := aTree.Items.AddChild(ANode,CurrStr);
                                  end
                                else
                                  begin
                                    CurrStr:= ReadString(aux,_Comp + IntToStr(i3) + _cStm,_Comp + IntToStr(i3) + _cStm);
                                    while ANode.Level > 3 do ANode := ANode.Parent; //Level 4
                                    ANode := aTree.Items.AddChild(ANode.Parent,CurrStr);
                                  end;
                              end;
                          end
                        else if ReadString(aux,_Kind, T_NONE) = T_MSG then
                          begin
                            CurrStr:= messLevel_04_M;
                            while ANode.Level > 3 do ANode := ANode.Parent;    //Level 4
                            ANode := aTree.Items.AddChild(ANode,CurrStr);
                          end
                        else if ReadString(aux,_Kind, T_NONE) = T_NONE then
                          begin
                            CurrStr:= T_NONE;
                            while ANode.Level > 3 do ANode := ANode.Parent;   //Level 4
                            ANode := aTree.Items.AddChild(ANode,CurrStr);
                          end
                    end;
                end;
              Result := True;
            end
          else ShowMessage(messuCfgSessionMainError);
        finally
          LIniFile.Free;
          aTree.EndUpdate;
        end;
  end;
end;

end.







