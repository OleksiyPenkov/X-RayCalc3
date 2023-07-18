(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_Config;

interface

uses forms, iniFiles, rtti, sysUtils, generics.Collections;

const
    DEFAULT_CONFIG_SECTION = 'COMMON';

type

  TSciRefSystemFile = (
    sfSystemIniFile,
    sfAppHelp,
    sfAppVerInfo,
    sfLicenseFile
  );

    /// <summary>
    ///     јтрибут класса названи¤ секции в INI-файле
    /// </summary>
    SectionAttribute = class(TCustomAttribute)
      strict private
        FSection : string;
      public
        constructor Create(SectionName : string);
        property Section : string read FSection;
    end;

    /// <summary>
    ///     «начение пол¤ по умолчанию (дл¤ int, bool, string)
    /// </summary>
    DefaultValueAttribute = class(TCustomAttribute)
      strict private
        FValue : TValue;
      public
        constructor Create(aIntValue : integer); overload;
        constructor Create(aBoolValue : boolean); overload;
        constructor Create(aStringValue : string); overload;
        property Value : TValue read FValue;
    end;

    /// <summary>
    ///    Ѕазовый класс доступа к свойствам.
    ///     аждое свойство дл¤ сохранени¤/получани¤ в INI *ƒолжно* иметь индекс.
    ///    в конечных классах дл¤ каждого типа свойсства следует указывать один из
    ///    методов чтени¤/записи:
    ///    - getIntegerValue/SetIntegerValue
    ///    - getBooleanValue/setBooleanValue
    ///    - getStringValue/SetStringValue
    ///    ѕеред каждым свойством должен быть описан атрибут DefaulValue
    ///    «начение по умолчанию строкового свойства может иметь подстроку
    ///    %PATH% дл¤ замены ее директорией программы, двойные "/" удал¤ютс¤
    /// </summary>
    TBaseOptions = class(TObject)
      strict protected
        FCtx : TRttiContext;
        FIni : TIniFile;
        FSection : string;
        function getDefaultAttribute(prop : TRttiProperty) : DefaultValueAttribute;

        function getGenericValue<T>(index : integer): T;
        procedure SetGenericValue<T>(index : integer; value : T);

        function getBooleanValue(index : integer):boolean; virtual;
        function getIntegerValue(index : integer):integer; virtual;
        function getStringValue(index : integer):string; virtual;

        procedure SetBooleanValue(index : integer; value : boolean); virtual;
        procedure SetIntegerValue(index : integer; value : integer); virtual;
        procedure SetStringValue(index : integer; value: string); virtual;

        function getProperty(index : integer) : TRttiProperty;
      public
        constructor Create(iniFile : TIniFile);
        destructor Destroy(); override;
    end;

    TBaseOptionsClass = class of TBaseOptions;

    [Section('Options')]
    TOtherOptions = class(TBaseOptions)
    public
      [DefaultValue(False)]
      property CheckForUpdates : boolean index 0 read getBooleanValue write SetBooleanValue;
      [DefaultValue('https://raw.githubusercontent.com/OleksiyPenkov/X-RayCalc3/xraycalc3.info')]
      property UpdateInfoURL : string index 1 read getStringValue write SetStringValue;
    end;

    [Section('Calc')]
    TCalcOptions = class(TBaseOptions)
    public
      [DefaultValue(-1)]
      property NumberOfThreads : integer index 0 read getIntegerValue write SetIntegerValue;
    end;

    [Section('Graphics')]
    TGraphOptions = class(TBaseOptions)
    public
      [DefaultValue(2)]
      property LineWidth: integer index 0 read getIntegerValue write SetIntegerValue;
    end;

    [Section('Path')]
    TPathOptions = class(TBaseOptions)
    public
      [DefaultValue('Henke')]
      property HenkeDir     : string index 0 read getStringValue write SetStringValue;
      [DefaultValue('benchmark')]
      property BenchmarkDir : string index 1 read getStringValue write SetStringValue;
    end;

    [Section('Window')]
    TWindowOptions = class(TBaseOptions)
      public
        [DefaultValue(0)]
        property State      : integer index 0 read getIntegerValue write SetIntegerValue;
        [DefaultValue(100)]
        property FormTop    : integer index 1 read getIntegerValue write SetIntegerValue;
        [DefaultValue(100)]
        property FormLeft   : integer index 2 read getIntegerValue write SetIntegerValue;
        [DefaultValue(900)]
        property FormWidth  : integer index 3 read getIntegerValue write SetIntegerValue;
        [DefaultValue(780)]
        property FormHeight : integer index 4 read getIntegerValue write SetIntegerValue;
        [DefaultValue(20)]
        property SplitterPR : integer index 5 read getIntegerValue write SetIntegerValue;
    end;

    /// <summary>
    ///      ласс дл¤ работы с настройками
    /// </summary>
    TConfig = class(TObject)
    strict private
       class var
        FIni: TIniFile;

        FAppPath : string;
        FErrorLog: Boolean;
        FTempDir: string;
        FWorkDir: string;

        FOptions : TObjectList<TBaseOptions>;
  private
    class function GetSystemFileName(fileType: TSciRefSystemFile): string; static;
    class function GetHenkePath: string; static;
    class function GetTempPath: string; static;
    class function GetHenkeDir: string; static;
    class function GetWorkPath: string; static;
    class function GetBenchDir: string; static;
    class function GetBenchPath: string; static;
  public
    class constructor Create();
    class destructor  Destroy();

    class procedure RegisterOptions(OptionsClass : TBaseOptionsClass);
    class function  Section<T:TBaseOptions>() : T;

    class property ErrorLog: Boolean read FErrorLog write FErrorLog;
    class property AppPath : string read FAppPath;

    class property HenkeDir: string read GetHenkeDir;
    class property HenkePath: string read GetHenkePath;

    class property BenchDir: string read GetBenchDir;
    class property BenchPath: string read GetBenchPath;

    class property WorkDir: string read FWorkDir;
    class property WorkPath: string read GetWorkPath;

    class property TempDir: string read FTempDir;
    class property TempPath: string read GetTempPath;

    class property SystemFileName[fileType: TSciRefSystemFile]: string read GetSystemFileName;
  end;

    EConfigException = Exception;

var
  Config: TConfig;

implementation
uses
  typinfo,
  System.StrUtils,
  unit_Consts,
  unit_Helpers,
  ShlObj;


{$REGION '--------------------- Create/Destroy ------------------------'}

class constructor TConfig.Create();
const
  STR_USELOCALDATA = 'uselocaldata';

var
  GlobalAppDataDir: string;
  IniFileName : string;
  UseLocalData: boolean;
begin
  FAppPath := ExtractFilePath(Application.ExeName);
  GlobalAppDataDir  := GetSpecialPath(CSIDL_APPDATA) + APPDATA_DIR_NAME;

  UseLocalData := FileExists(FAppPath + STR_USELOCALDATA);

  FWorkDir := IfThen(UseLocalData, ExcludeTrailingPathDelimiter(FAppPath), GlobalAppDataDir);
  FTempDir := c_GetTempPath + APPDATA_DIR_NAME;

  CreateFolders('', FTempDir);
  CreateFolders('', FWorkDir);

  IniFileName := WorkPath + SETTINGS_FILE_NAME;
  FIni := TIniFile.Create(IniFileName);

  FOptions := TObjectList<TBaseOptions>.Create();

  TConfig.RegisterOptions(TPathOptions);
  TConfig.RegisterOptions(TWindowOptions);
  TConfig.RegisterOptions(TOtherOptions);
  TConfig.RegisterOptions(TGraphOptions);
  TConfig.RegisterOptions(TCalcOptions);
end;

class destructor TConfig.Destroy;
begin
  FOptions.Free();
  FIni.Free();
end;

class function TConfig.GetBenchDir: string;
begin
  Result := FAppPath + TConfig.Section<TPathOptions>.BenchmarkDir;
end;


class function TConfig.GetHenkeDir: string;
begin
  Result := FAppPath + TConfig.Section<TPathOptions>.HenkeDir;
end;

class function TConfig.GetHenkePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetHenkeDir);
end;

class function TConfig.GetSystemFileName(fileType: TSciRefSystemFile): string;
begin
 case fileType of
    sfAppHelp: Result          := AppPath + APP_HELP_FILENAME;
    sfLicenseFile: Result      := WorkPath + LICENSE_FILENAME;
  else
    Assert(False);
  end;
end;

class function TConfig.GetTempPath: string;
begin
  Result := IncludeTrailingPathDelimiter(FTempDir);
end;

class function TConfig.GetWorkPath: string;
begin
  Result := IncludeTrailingPathDelimiter(FWorkDir);
end;

class function TConfig.GetBenchPath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetBenchDir);
end;

class procedure TConfig.RegisterOptions(OptionsClass: TBaseOptionsClass);
var opt : TBaseOptions;
begin
    opt := OptionsClass.Create(FIni);
    FOptions.Add(opt);
end;

class function TConfig.Section<T>(): T;
var opt : TBaseOptions;
    ti : TRttiType;
    ctx : TRttiContext;
begin
    ti := ctx.GetType(typeInfo(T));
    try
        for opt in FOptions do begin
            if opt is ti.AsInstance.MetaclassType then
                exit(T(opt));
        end;
    finally
        ctx.Free();
    end;

    raise EConfigException.Create('Unregistered option group' + string(PTypeInfo(typeinfo(t)).Name));
end;

{$ENDREGION}

{$REGION '--------------------- TBaseOptions --------------------------'}
constructor TBaseOptions.Create(iniFile: TIniFile);
var ctx : TRttiContext;
    attr : TCustomAttribute;
    t : TRttiType;
begin
    inherited Create();
    FIni := iniFile;

    FCtx  := TRttiContext.Create();
    t := ctx.GetType(self.ClassType);
    for attr in t.GetAttributes() do begin
        if attr is SectionAttribute then begin
            FSection := SectionAttribute(attr).Section;
        end;
    end;
end;

destructor TBaseOptions.Destroy();
begin
    FCtx.Free();
    inherited;
end;

/// <summary>
/// извлечение атрибута DefaultValue дл¤ свойства
/// </summary>
function TBaseOptions.getDefaultAttribute(prop: TRttiProperty): DefaultValueAttribute;
var attr : TCustomAttribute;
begin
  result := nil;
  for attr in prop.GetAttributes() do begin
      if attr is DefaultValueAttribute then begin
          result := attr as DefaultValueAttribute;
          exit;
      end;
  end;
end;

{$REGION '--------------------- get-Methods ---------------------------}
/// <summary>
///     Generic метод получен¤и значени¤ свойства.
///  если свойство в INI отсутствует, то возвращаетс¤ значение атрибута DefaultValue
///  если атрибут не указан, то Default(T)
/// </summary>
function TBaseOptions.getGenericValue<T>(index: integer): T;
var prop : TRttiProperty;
    default : DefaultValueAttribute;
    value : TValue;
begin
    prop := getProperty(index);
    if not assigned(prop) then
        raise EConfigException.Create('Undefined property name');

    default := getDefaultAttribute(prop);

    if FIni.ValueExists(FSection, Prop.Name) then begin

        case prop.PropertyType.TypeKind of
            tkInteger : value := FIni.ReadInteger(FSection, prop.name, Default.Value.AsInteger);
            tkString,
            tkUString : value := FIni.ReadString(FSection, prop.Name, Default.Value.asString);
            tkEnumeration : value := FIni.ReadInteger(FSection, prop.Name, ord(Default.Value.AsBoolean)) <> 0;
        end;

        result := value.AsType<T>;
    end
    else begin
        if assigned(default) then
             result := default.Value.AsType<T>
        else result := system.Default(T);
    end;
end;

function TBaseOptions.getBooleanValue(index: integer): boolean;
begin
    result := getGenericValue<boolean>(index);
end;

function TBaseOptions.getIntegerValue(index: integer): integer;
begin
    result := getGenericValue<integer>(index);
end;

function TBaseOptions.getStringValue(index: integer): string;
begin
    result := getGenericValue<string>(index);
    if ContainsText(result, '%PATH%') then begin
         result := ReplaceText(result, '%PATH%', TConfig.AppPath);
         result := ReplaceText(result, '\\', '\');
    end;
end;
{$ENDREGION}


{$REGION '--------------------- set Methods ---------------------------'}

/// <summary>
///     Generic-метод записи свойства в INI файл.
/// </summary>
procedure TBaseOptions.SetGenericValue<T>(index: integer; value: T);
var prop : TRttiProperty;
    newValue : TValue;
begin

    prop := getProperty(index);
    if not assigned(prop) then
        raise EConfigException.Create('Undefined property name');

    newValue := TValue.From<T>(value);

    case PTypeInfo(TypeInfo(T)).Kind of
        tkInteger : FIni.WriteInteger(FSection, prop.Name, newValue.AsInteger);
        tkString,
        tkUString : Fini.WriteString(FSection, prop.Name, newValue.AsString);
        tkEnumeration : FIni.WriteBool(FSection, prop.Name, newValue.AsBoolean);
    end;
end;

procedure TBaseOptions.SetBooleanValue(index: integer; value: boolean);
begin
    setGenericValue<boolean>(index, value);
end;


procedure TBaseOptions.SetIntegerValue(index, value: integer);
begin
    setGenericValue<integer>(index, value);
end;

procedure TBaseOptions.SetStringValue(index: integer; value: string);
begin
    setGenericValue<string>(index, value);
end;
{$ENDREGION}

/// <summary>
///     —войство класса по его индексу
/// </summary>
function TBaseOptions.getProperty(index: integer): TRttiProperty;
var t : TRttiType;
    props : TArray<TRttiProperty>;
begin
  t := FCtx.GetType(self.ClassType);
  props := t.GetProperties();
  if index > Length(props) then
      raise EArgumentOutOfRangeException.Create(Format('TPrnsConfig. Property %d does not exists',[index]));
  result := props[index];
end;


{$ENDREGION}

{$REGION '--------------------- Attributes --------------------------'}
{ TSectionAttribute }

constructor SectionAttribute.Create(SectionName: string);
begin
    inherited Create();
    FSection := SectionName;
end;

{ DefaultValueAttribute }

constructor DefaultValueAttribute.Create(aIntValue: integer);
begin
    inherited Create();
    FValue := aIntValue;
end;

constructor DefaultValueAttribute.Create(aBoolValue: boolean);
begin
    inherited Create();
    FValue := aBoolValue;
end;

constructor DefaultValueAttribute.Create(aStringValue: string);
begin
    inherited Create();
    FValue := aStringValue;
end;

{$ENDREGION}

initialization

finalization

end.
