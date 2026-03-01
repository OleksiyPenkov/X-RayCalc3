unit frame_StructurePanel;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Buttons, Vcl.ImgList,
  RzPanel, RzButton, RzCmboBx;

type
  TfrmStructurePanel = class(TFrame)
    tlbStructure: TRzToolbar;
    btnPeriodAdd: TRzToolButton;
    btnPeriodInsert: TRzToolButton;
    btnPeriodDelete: TRzToolButton;
    rzspcr1: TRzSpacer;
    btnLayerAdd: TRzToolButton;
    btnLayerInsert: TRzToolButton;
    btnLayerPaste: TRzToolButton;
    btnLayerDelete: TRzToolButton;
    btnLayerCut: TRzToolButton;
    RzSpacer3: TRzSpacer;
    btnCopyLayer: TRzToolButton;
    RzPanel2: TRzPanel;
    Label6: TLabel;
    cbIncrement: TRzComboBox;
    btnSetFitLimits: TBitBtn;
    procedure cbIncrementChange(Sender: TObject);
    procedure btnSetFitLimitsClick(Sender: TObject);
  private
    FOnIncrementChange: TNotifyEvent;
    FOnSetFitLimits: TNotifyEvent;
  public
    procedure ConnectActions(AImages: TCustomImageList;
      APeriodAdd, APeriodInsert, APeriodDelete,
      ALayerAdd, ALayerInsert, ALayerCopy, ALayerCut, ALayerPaste, ALayerDelete: TBasicAction);
    function IncrementValue: Double;
    procedure SetToolbarEnabled(Value: Boolean);

    property OnIncrementChange: TNotifyEvent read FOnIncrementChange write FOnIncrementChange;
    property OnSetFitLimits: TNotifyEvent read FOnSetFitLimits write FOnSetFitLimits;
  end;

implementation

{$R *.dfm}

{ TfrmStructurePanel }

procedure TfrmStructurePanel.ConnectActions(AImages: TCustomImageList;
  APeriodAdd, APeriodInsert, APeriodDelete,
  ALayerAdd, ALayerInsert, ALayerCopy, ALayerCut, ALayerPaste, ALayerDelete: TBasicAction);

  procedure AssignAction(AButton: TRzToolButton; AAction: TBasicAction);
  var
    SavedIndex: Integer;
  begin
    SavedIndex := AButton.ImageIndex;
    AButton.Action := AAction;
    AButton.ImageIndex := SavedIndex;
  end;

begin
  tlbStructure.Images := AImages;
  AssignAction(btnPeriodAdd, APeriodAdd);
  AssignAction(btnPeriodInsert, APeriodInsert);
  AssignAction(btnPeriodDelete, APeriodDelete);
  AssignAction(btnLayerAdd, ALayerAdd);
  AssignAction(btnLayerInsert, ALayerInsert);
  AssignAction(btnCopyLayer, ALayerCopy);
  AssignAction(btnLayerCut, ALayerCut);
  AssignAction(btnLayerPaste, ALayerPaste);
  AssignAction(btnLayerDelete, ALayerDelete);
end;

procedure TfrmStructurePanel.cbIncrementChange(Sender: TObject);
begin
  if Assigned(FOnIncrementChange) then
    FOnIncrementChange(Self);
end;

procedure TfrmStructurePanel.btnSetFitLimitsClick(Sender: TObject);
begin
  if Assigned(FOnSetFitLimits) then
    FOnSetFitLimits(Self);
end;

function TfrmStructurePanel.IncrementValue: Double;
begin
  Result := StrToFloat(cbIncrement.Value);
end;

procedure TfrmStructurePanel.SetToolbarEnabled(Value: Boolean);
begin
  tlbStructure.Enabled := Value;
end;

end.
