unit CoreDB;

interface

uses
  SysUtils, SQLiteTable3, Classes, system.Generics.Collections;

type
  // datArr=array of array of Variant;
  tbasedb = class
  end;

  TDestTopDB = class(tbasedb)
  public
    constructor Create();
    destructor destroy; override;
    function CheckExists(FileName: string): Boolean;
    function SaveToDB(Path, FileName: string): Boolean;
    function GetFile: TStringList;
    function DeleteRecord(FileName: string): Boolean;
    function DeleteAll(): Boolean;
    function UpdateRecord(Path, Rename: string): Boolean;
    function UpdateSearchUrl(url: string): Boolean;
    function GetSearchUrl: string;
    function UpdateToolbar(inx: Integer; url, hint: string): Boolean;
    function GetToolbarUrl(inx: Integer): string;
  end;

  TBasProfileDB = class(tbasedb)
  public
    function GetString(ValName: string): string;
    function GetInteger(ValName: string): Integer;
    function GetBoolean(ValName: string; ADefault: Boolean = false): Boolean;
    procedure SetVarValue(ValName: string; val: Variant);
    procedure SetValue(ValName: string; val: string); overload;
    procedure SetValue(ValName: string; val: Integer); overload;
    procedure SetValue(ValName: string; val: Boolean); overload;
    procedure SetValue(ValName: string; val: Double); overload;
    procedure DeleteValue(ValName: string);
    function GetKeys(AKey: string): string;
  public
    constructor Create();
    destructor destroy; override;
  end;

  TfilesDB = class(tbasedb)
  public
    function GetString(ValName: string): string;
    function GetInteger(ValName: string): Integer;
    function GetBoolean(ValName: string; ADefault: Boolean = false): Boolean;
    procedure SetVarValue(ValName: string; val: Variant);
    procedure SetValue(ValName: string; val: string); overload;
    procedure SetValue(ValName: string; val: Integer); overload;
    procedure SetValue(ValName: string; val: Boolean); overload;
    procedure SetValue(ValName: string; val: Double); overload;
    procedure DeleteValue(ValName: string);
    function GetKeys(): tlist<string>;
    procedure clean;
  public
    constructor Create();
    destructor destroy; override;
  end;

  TEnglishDb = class
  public
    procedure DeleteValue(ValName: string);
    function GetBoolean(ValName: string; ADefault: Boolean): Boolean; overload;
    function GetInteger(ValName: string): Integer;
    function GetKeys(AKey: string): string;
    function GetString(ValName: string): string;
    procedure SetValue(ValName: string; val: Integer); overload;
    procedure SetVarValue(ValName: string; val: Variant);
    procedure SetValue(ValName, val: string); overload;
    procedure SetValue(ValName: string; val: Double); overload;
    procedure SetValue(ValName: string; val: Boolean); overload;
  public
    constructor Create();
    destructor destroy; override;
  end;

  tgdb = record
    syspara: TBasProfileDB;
    DestTopDB: TDestTopDB;
    filesDB: TfilesDB;
    engdb: TEnglishDb;
  end;

implementation

uses
  core;

var
  sldb: TSQLiteDatabase;
  sltb: TSQLIteTable;
  { TDragExeDB }

function TDestTopDB.CheckExists(FileName: string): Boolean;
var
  SQLTemp: string;
begin
  SQLTemp := 'Select 1 ' + ' From DestTop ' + ' Where Path=' + Quotedstr(FileName);

  if sldb.GetTableString(SQLTemp) <> '' then
    Result := false
  else
    Result := True;
end;

destructor TDestTopDB.destroy;
begin
  sldb.Free;
  inherited;
end;

constructor TDestTopDB.Create;
var
  ssql: string;
  ss: string;
begin
  inherited Create();

  if not sldb.TableExists('DestTop') then
  begin
    ssql := 'CREATE TABLE DestTop ([ID] INTEGER PRIMARY KEY,path varchar(200),FileName varChar(50) )';
    sldb.execsql(ssql);
    sldb.execsql('CREATE INDEX DestTopfilename ON [DestTop]([FileName]);');
  end;
  // sSQL := 'DROP TABLE DestTop';
  if not sldb.TableExists('DestTopSearch') then
  begin
    ssql := 'CREATE TABLE DestTopSearch ([ID] INTEGER PRIMARY KEY,url varchar(200) )';
    sldb.execsql(ssql);
    sldb.execsql('CREATE INDEX DestTopSearchIndx ON [DestTopSearch]([url]);');
    ss := 'http://www.baidu.com/#wd=';
    ss := Format('Insert Into DestTopSearch(url) Values(''%s'')', [ss]);
    sldb.execsql(ss);

  end;

  if not sldb.TableExists('toolbar') then
  begin
    ssql := 'CREATE TABLE toolbar ([ID] INTEGER PRIMARY KEY,idx integer,url varchar(200),hint varchar(200) )';
    sldb.execsql(ssql);
    sldb.execsql('CREATE INDEX toolbarIndx ON [toolbar]([idx]);');
    ss := Format('Insert Into toolbar(idx,url,hint) Values(1,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(2,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(3,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(4,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(5,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(6,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(7,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(8,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    /// /////////////
    ss := Format('Insert Into toolbar(idx,url,hint) Values(9,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);

    ss := Format('Insert Into toolbar(idx,url,hint) Values(10,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);

    ss := Format('Insert Into toolbar(idx,url,hint) Values(11,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
    ss := Format('Insert Into toolbar(idx,url,hint) Values(12,''%s'',''%s'')', ['', '']);
    sldb.execsql(ss);
  end;
end;

function TDestTopDB.SaveToDB(Path, FileName: string): Boolean;
var
  SQLTemp: string;
begin

  Result := True;
  SQLTemp := Format('Insert Into DestTop(path,FileName) Values(''%s'',''%s'')', [Path, FileName]);
  try
    sldb.BeginTransaction;
    sldb.execsql(SQLTemp);
    sldb.Commit;
  except
    sldb.RollBack;
    Result := false;
  end;

end;

function TDestTopDB.GetFile: TStringList;
var
  SQLTemp: string;
  pageCount: Integer;
  k, i, j, l: Integer;
begin
  SQLTemp := 'Select path,FileName From DestTop ';
  sltb := sldb.GetTable(SQLTemp);
  Result := TStringList.Create;
  sltb.MoveFirst;
  if sltb.Count > 0 then
    while not sltb.EOF do
    begin
      Result.Add(sltb.FieldAsString(sltb.FieldIndex['FileName']) + ',' + sltb.FieldAsString(sltb.FieldIndex['path']));
      sltb.Next;
    end;
end;

function TDestTopDB.DeleteAll(): Boolean;
var
  SQL: string;
begin
  SQL := 'Delete From DestTop';
  try
    sldb.BeginTransaction;
    sldb.execsql(SQL);
    sldb.Commit;
  except
    sldb.RollBack;
  end;

end;

function TDestTopDB.DeleteRecord(FileName: string): Boolean;
var
  SQL: string;
begin
  SQL := 'Delete From DestTop' + ' Where  FileName=' + Quotedstr(FileName);
  try
    sldb.BeginTransaction;
    sldb.execsql(SQL);
    sldb.Commit;
  except
    sldb.RollBack;
  end;
end;

function TDestTopDB.UpdateRecord(Path, Rename: string): Boolean;
var
  SQL: string;
begin
  SQL := 'update DestTop' + ' Set FileName =' + Quotedstr(Rename) + ' Where  path=' + Quotedstr(Path);
  try
    sldb.BeginTransaction;
    sldb.execsql(SQL);
    sldb.Commit;
  except
    sldb.RollBack;
  end;
end;

function TDestTopDB.GetToolbarUrl(inx: Integer): string;
var
  SQLTemp: string;
  pageCount: Integer;
  k, i, j, l: Integer;
begin
  Result := '';
  try
    SQLTemp := 'Select url,hint From toolbar where idx=' + IntToStr(inx);
    sltb := sldb.GetTable(SQLTemp);

    sltb.MoveFirst;
    if sltb.Count > 0 then
      Result := sltb.FieldAsString(sltb.FieldIndex['url']) + '^' + sltb.FieldAsString(sltb.FieldIndex['hint']);
  except

  end;
end;

function TDestTopDB.UpdateToolbar(inx: Integer; url, hint: string): Boolean;
var
  SQL: string;
begin
  SQL := 'update toolbar' + ' Set url =' + Quotedstr(url) + ',  hint =' + Quotedstr(hint) + ' Where  idx=' + IntToStr(inx);
  try
    sldb.BeginTransaction;
    sldb.execsql(SQL);
    sldb.Commit;
  except
    sldb.RollBack;
  end;
end;
// ss := Format('Insert Into toolbar(idx,url,hint) Values(6,''%s'',''%s'')', [ 'notepad.exe','±Ê¼Ç']);

function TDestTopDB.GetSearchUrl: string;
var
  SQLTemp: string;
  pageCount: Integer;
  k, i, j, l: Integer;
begin
  Result := '';
  SQLTemp := 'Select url From DestTopSearch ';
  sltb := sldb.GetTable(SQLTemp);

  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['url']));

end;

function TDestTopDB.UpdateSearchUrl(url: string): Boolean;
var
  SQL: string;
begin
  SQL := 'update DestTopSearch' + ' Set url =' + Quotedstr(url);
  try
    sldb.BeginTransaction;
    sldb.execsql(SQL);
    sldb.Commit;
  except
    sldb.RollBack;
  end;
end;
{ TBasProfileDB }

constructor TBasProfileDB.Create;
var
  FInitSQL: string;
begin
  FInitSQL := 'Create Table SysProfile(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_SysProfile_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('SysProfile') then
  begin
    sldb.execsql(FInitSQL);
  end;
end;

procedure TBasProfileDB.DeleteValue(ValName: string);
begin
  sldb.execsql('delete from SysProfile where ValKey=''' + ValName + '''');
end;

destructor TBasProfileDB.destroy;
begin

  inherited;
end;

function TBasProfileDB.GetBoolean(ValName: string; ADefault: Boolean): Boolean;
var
  r: string;
begin
  Result := ADefault;
  r := GetString(ValName);
  if r = '' then
    exit;
  Result := UpperCase(r) <> 'FALSE';

end;

function TBasProfileDB.GetInteger(ValName: string): Integer;
var
  r: string;
begin
  Result := -1;
  r := GetString(ValName);
  if r='' then  result:=0 else

  Result := Trunc(StrToFloat(r));
end;

function TBasProfileDB.GetKeys(AKey: string): string;
begin
  sltb := sldb.GetTable('Select ValKey from SysProfile where ValKey like ''' + AKey + '%'' order by ID asc');

  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['ValKey']));
end;

function TBasProfileDB.GetString(ValName: string): string;
var
  sltb: TSQLiteTable;
begin
  sltb := sldb.GetTable('select Value from SysProfile where ValKey=''' + ValName + '''');
  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));
  if sltb <> nil then
    FreeAndNil(sltb);
end;

procedure TBasProfileDB.SetValue(ValName: string; val: Integer);
begin
  SetVarValue(ValName, val);
end;

procedure TBasProfileDB.SetValue(ValName, val: string);
begin
  SetVarValue(ValName, val);
end;

procedure TBasProfileDB.SetValue(ValName: string; val: Double);
begin
  SetVarValue(ValName, val);
end;

procedure TBasProfileDB.SetValue(ValName: string; val: Boolean);
begin
  SetVarValue(ValName, val);
end;

procedure TBasProfileDB.SetVarValue(ValName: string; val: Variant);
var
  SQL: string;
  c: Integer;
begin
  try

    sltb := sldb.GetTable(Format('select count(*) as co from SysProfile where ValKey=''%s''', [ValName]));

    sltb.MoveFirst;
    if sltb.Count > 0 then
      c := (sltb.FieldAsInteger(sltb.FieldIndex['co']));
    if c = 0 then
    begin
      SQL := Format('Insert Into SysProfile(ValKey, Value) Values(''%s'', ''%s'')', [ValName, val])
    end
    else
    begin
      SQL := Format('update SysProfile Set Value=''%s'' where ValKey=''%s''', [val, ValName]);

    end;
    try
      sldb.BeginTransaction;
      sldb.execsql(SQL);
      sldb.Commit;
    except
      sldb.RollBack;
    end;

  finally

  end;

end;

{ TEnglishDb }

constructor TEnglishDb.Create;
var
  FInitSQL: string;
begin
  FInitSQL := 'Create Table engdb(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_engdb_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('engdb') then
  begin
    sldb.execsql(FInitSQL);
  end;
end;

destructor TEnglishDb.destroy;
begin

  inherited;
end;

procedure TEnglishDb.DeleteValue(ValName: string);
begin
  sldb.execsql('delete from engdb where ValKey=''' + ValName + '''');
end;

function TEnglishDb.GetBoolean(ValName: string; ADefault: Boolean): Boolean;
var
  r: string;
begin
  Result := ADefault;
  r := GetString(ValName);
  if r = '' then
    exit;
  Result := r <> '0';

end;

function TEnglishDb.GetInteger(ValName: string): Integer;
var
  r: string;
begin
  Result := -1;
  r := GetString(ValName);
  Result := Trunc(StrToFloat(r));
end;

function TEnglishDb.GetKeys(AKey: string): string;
begin
  sltb := sldb.GetTable('Select ValKey from engdb where ValKey like ''' + AKey + '%'' order by ID asc');

  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['ValKey']));
end;

function TEnglishDb.GetString(ValName: string): string;
begin
  sltb := sldb.GetTable('select Value from engdb where ValKey=''' + ValName + '''');

  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));

end;

procedure TEnglishDb.SetValue(ValName: string; val: Integer);
begin
  SetVarValue(ValName, val);
end;

procedure TEnglishDb.SetValue(ValName, val: string);
begin
  SetVarValue(ValName, val);
end;

procedure TEnglishDb.SetValue(ValName: string; val: Double);
begin
  SetVarValue(ValName, val);
end;

procedure TEnglishDb.SetValue(ValName: string; val: Boolean);
begin
  SetVarValue(ValName, val);
end;

procedure TEnglishDb.SetVarValue(ValName: string; val: Variant);
var
  SQL: string;
  c: Integer;
begin
  try

    sltb := sldb.GetTable(Format('select count(*) as co from engdb where ValKey=''%s''', [ValName]));

    sltb.MoveFirst;
    if sltb.Count > 0 then
      c := (sltb.FieldAsInteger(sltb.FieldIndex['co']));
    if c = 0 then
    begin
      SQL := Format('Insert Into engdb(ValKey, Value) Values(''%s'', ''%s'')', [ValName, val])
    end
    else
    begin
      SQL := Format('update engdb Set Value=''%s'' where ValKey=''%s''', [val, ValName]);

    end;
    try
      sldb.BeginTransaction;
      sldb.execsql(SQL);
      sldb.Commit;
    except
      sldb.RollBack;
    end;

  finally

  end;

end;

{ TfilesDB }

//constructor TfilesDB.Create;
//begin
//
//end;

constructor TfilesDB.Create;
var
  FInitSQL: string;            //SysProfile
begin
  FInitSQL := 'Create Table filesdb(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_SysProfile_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('filesdb') then
  begin
    sldb.execsql(FInitSQL);
  end;
end;

procedure TfilesDB.DeleteValue(ValName: string);
begin
  sldb.execsql('delete from filesdb where ValKey=''' + ValName + '''');
end;

procedure TfilesDB.clean();
begin
  sldb.execsql('delete from filesdb ');
end;

destructor TfilesDB.destroy;
begin

  inherited;
end;

function TfilesDB.GetBoolean(ValName: string; ADefault: Boolean): Boolean;
var
  r: string;
begin
  Result := ADefault;
  r := GetString(ValName);
  if r = '' then
    exit;
  Result := UpperCase(r) <> 'FALSE';

end;

function TfilesDB.GetInteger(ValName: string): Integer;
var
  r: string;
begin
  Result := -1;
  r := GetString(ValName);
  Result := Trunc(StrToFloat(r));
end;

function TfilesDB.GetKeys(): tlist<string>;
var
  sltb: TSQLiteTable;
begin
  sltb := sldb.GetTable('Select ValKey from filesdb ');
  result := TList<string>.Create;
  while not sltb.EOF do
  begin
    result.Add(sltb.FieldAsString(sltb.FieldIndex['ValKey']));
    sltb.Next;
  end;
  if sltb <> nil then
    FreeAndNil(sltb);
end;

function TfilesDB.GetString(ValName: string): string;
var
  sltb: TSQLiteTable;
begin
  sltb := sldb.GetTable('select Value from filesdb where ValKey=''' + ValName + '''');
  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));
  if sltb <> nil then
    FreeAndNil(sltb);
end;

procedure TfilesDB.SetValue(ValName: string; val: Integer);
begin
  SetVarValue(ValName, val);
end;

procedure TfilesDB.SetValue(ValName, val: string);
begin
  SetVarValue(ValName, val);
end;

procedure TfilesDB.SetValue(ValName: string; val: Double);
begin
  SetVarValue(ValName, val);
end;

procedure TfilesDB.SetValue(ValName: string; val: Boolean);
begin
  SetVarValue(ValName, val);
end;

procedure TfilesDB.SetVarValue(ValName: string; val: Variant);
var
  SQL: string;
  c: Integer;
begin
  try

    sltb := sldb.GetTable(Format('select count(*) as co from filesdb where ValKey=''%s''', [ValName]));

    sltb.MoveFirst;
    if sltb.Count > 0 then
      c := (sltb.FieldAsInteger(sltb.FieldIndex['co']));
    if c = 0 then
    begin
      SQL := Format('Insert Into filesdb(ValKey, Value) Values(''%s'', ''%s'')', [ValName, val])
    end
    else
    begin
      SQL := Format('update filesdb Set Value=''%s'' where ValKey=''%s''', [val, ValName]);

    end;
    try
      sldb.BeginTransaction;
      sldb.execsql(SQL);
      sldb.Commit;
    except
      sldb.RollBack;
    end;

  finally

  end;

end;

initialization
//
  if sldb = nil then
    sldb := TSQLiteDatabase.Create(ExtractFilepath(ParamStr(0)) + 'DestTopdb.db');
  if g_core.db.DestTopDB = nil then
    g_core.db.DestTopDB := TDestTopDB.Create;
  if g_core.db.syspara = nil then
    g_core.db.syspara := TBasProfileDB.Create;

  if g_core.db.filesDB = nil then
    g_core.db.filesDB := TfilesDB.Create;


finalization
  if g_core.db.DestTopDB <> nil then
    FreeAndNil(g_core.db.DestTopDB);
  if g_core.db.syspara <> nil then
    FreeAndNil(g_core.db.syspara);

  if g_core.db.filesDB <> nil then
    FreeAndNil(g_core.db.filesDB);

end.

