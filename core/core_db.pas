unit core_db;

interface

uses
  SysUtils, SQLiteTable3, Classes, system.Generics.Collections;

type
  tbasedb = class
  end;

  TdesktopDb = class
  public
    function GetString(ValName: string): string;

    procedure SetVarValue(ValName: string; val: Variant);

    procedure DeleteValue(ValName: string);
    function GetKeys(): tlist<string>;
    procedure clean();
  public
    constructor Create();
    destructor destroy; override;
  end;

  TItemsDb = class
  public
    function GetString(ValName: string; keyflag: boolean = true): string;

    procedure SetVarValue(ValName: string; val: Variant; keyflag: boolean = true);

    procedure DeleteValue(ValName: string; keyflag: boolean = true);
    function GetKeys(keyflag: boolean = true): tlist<string>;
    procedure clean(keyflag: boolean = true);
  public
    constructor Create();
    destructor destroy; override;
  end;

  TCfgDB = class(tbasedb)
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



  tgdb = record
    cfgDb: TCfgDB;
    itemDb: TItemsDb;
    desktopDb: TdesktopDb;
  end;

var
  sldb: TSQLiteDatabase;
  sltb: TSQLIteTable;

implementation

uses
  core;



{ œµÕ≥≈‰÷√ }
constructor TCfgDB.Create;
var
  FInitSQL: string;
begin
  FInitSQL := 'Create Table SysProfile(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_SysProfile_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('SysProfile') then
  begin
    sldb.execsql(FInitSQL);
  end;
end;

procedure TCfgDB.DeleteValue(ValName: string);
begin
  sldb.execsql('delete from SysProfile where ValKey=''' + ValName + '''');
end;

destructor TCfgDB.destroy;
begin

  inherited;
end;

function TCfgDB.GetBoolean(ValName: string; ADefault: Boolean): Boolean;
var
  r: string;
begin
  Result := ADefault;
  r := GetString(ValName);
  if r = '' then
    exit;
  Result := UpperCase(r) <> 'FALSE';

end;

function TCfgDB.GetInteger(ValName: string): Integer;
var
  r: string;
begin
  Result := -1;
  r := GetString(ValName);
  if r = '' then
    Result := 0
  else

    Result := Trunc(StrToFloat(r));
end;

function TCfgDB.GetKeys(AKey: string): string;
begin
  sltb := sldb.GetTable('Select ValKey from SysProfile where ValKey like ''' + AKey + '%'' order by ID asc');

  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['ValKey']));
end;

function TCfgDB.GetString(ValName: string): string;
var
  sltb: TSQLIteTable;
begin
  sltb := sldb.GetTable('select Value from SysProfile where ValKey=''' + ValName + '''');
  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));
  if sltb <> nil then
    FreeAndNil(sltb);
end;

procedure TCfgDB.SetValue(ValName: string; val: Integer);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetValue(ValName, val: string);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetValue(ValName: string; val: Double);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetValue(ValName: string; val: Boolean);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetVarValue(ValName: string; val: Variant);
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


{ TItems<T> }

procedure TItemsDb.clean(keyflag: boolean);
begin
  if keyflag then
    sldb.execsql('delete from keysdb ')
  else
    sldb.execsql('delete from valuesdb ');
end;

constructor TItemsDb.Create;
var
  FInitSQL: string;
begin
  FInitSQL := 'Create Table keysdb(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_SysProfile_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('keysdb') then
  begin
    sldb.execsql(FInitSQL);
  end;

  FInitSQL := 'Create Table valuesdb(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_SysProfile_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('valuesdb') then
  begin
    sldb.execsql(FInitSQL);
  end;

end;

procedure TItemsDb.DeleteValue(ValName: string; keyflag: boolean);
begin
  if keyflag then
    sldb.execsql('delete from keysdb where ValKey=''' + ValName + '''')
  else
    sldb.execsql('delete from valuesdb where ValKey=''' + ValName + '''');
end;

destructor TItemsDb.destroy;
begin

  inherited;
end;

function TItemsDb.GetKeys(keyflag: boolean): tlist<string>;
var
  sltb: TSQLIteTable;
begin
  if keyflag then
  begin

    sltb := sldb.GetTable('Select ValKey from keysdb ');
    Result := tlist<string>.Create;
    while not sltb.EOF do
    begin
      Result.Add(sltb.FieldAsString(sltb.FieldIndex['ValKey']));
      sltb.Next;
    end;
  end
  else
  begin
    sltb := sldb.GetTable('Select ValKey from valuesdb ');
    Result := tlist<string>.Create;
    while not sltb.EOF do
    begin
      Result.Add(sltb.FieldAsString(sltb.FieldIndex['ValKey']));
      sltb.Next;
    end;
  end;

  if sltb <> nil then
    FreeAndNil(sltb);

end;

function TItemsDb.GetString(ValName: string; keyflag: boolean): string;
var
  sltb: TSQLIteTable;
begin
  if keyflag then
  begin
    sltb := sldb.GetTable('select Value from keysdb where ValKey=''' + ValName + '''');
    sltb.MoveFirst;
    if sltb.Count > 0 then
      Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));
  end
  else
  begin
    sltb := sldb.GetTable('select Value from valuesdb where ValKey=''' + ValName + '''');
    sltb.MoveFirst;
    if sltb.Count > 0 then
      Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));
  end;
  if sltb <> nil then
    FreeAndNil(sltb);

end;

procedure TItemsDb.SetVarValue(ValName: string; val: Variant; keyflag: boolean);
var
  SQL: string;
  c: Integer;
begin
  if keyflag then
  begin

    sltb := sldb.GetTable(Format('select count(*) as co from keysdb where ValKey=''%s''', [ValName]));

    sltb.MoveFirst;
    if sltb.Count > 0 then
      c := (sltb.FieldAsInteger(sltb.FieldIndex['co']));
    if c = 0 then
    begin
      SQL := Format('Insert Into keysdb(ValKey, Value) Values(''%s'', ''%s'')', [ValName, val])
    end
    else
    begin
      SQL := Format('update keysdb Set Value=''%s'' where ValKey=''%s''', [val, ValName]);

    end;
    try
      sldb.BeginTransaction;
      sldb.execsql(SQL);
      sldb.Commit;
    except
      sldb.RollBack;
    end;

  end
  else

  begin

    sltb := sldb.GetTable(Format('select count(*) as co from valuesdb where ValKey=''%s''', [ValName]));

    sltb.MoveFirst;
    if sltb.Count > 0 then
      c := (sltb.FieldAsInteger(sltb.FieldIndex['co']));
    if c = 0 then
    begin
      SQL := Format('Insert Into valuesdb(ValKey, Value) Values(''%s'', ''%s'')', [ValName, val])
    end
    else
    begin
      SQL := Format('update valuesdb Set Value=''%s'' where ValKey=''%s''', [val, ValName]);

    end;
    try
      sldb.BeginTransaction;
      sldb.execsql(SQL);
      sldb.Commit;
    except
      sldb.RollBack;
    end;

  end;

end;

{ TdesktopDb }

procedure TdesktopDb.clean();
begin
  sldb.execsql('delete from desktopdb ');
end;

constructor TdesktopDb.Create;
begin
  var FInitSQL := 'Create Table desktopdb(ID Integer Primary Key, ' + 'ValKey varchar(50) COLLATE NOCASE, Value varchar(400) COLLATE NOCASE);' + 'Create Index idx_SysProfile_ValKey On SysProfile(ValKey)';

  if not sldb.TableExists('desktopdb') then
  begin
    sldb.execsql(FInitSQL);
  end;

end;

procedure TdesktopDb.DeleteValue(ValName: string);
begin

  sldb.execsql('delete from desktopdb where ValKey=''' + ValName + '''')

end;

destructor TdesktopDb.destroy;
begin

  inherited;
end;

function TdesktopDb.GetKeys(): tlist<string>;
var
  sltb: TSQLIteTable;
begin

  sltb := sldb.GetTable('Select ValKey from desktopdb ');
  Result := tlist<string>.Create;
  while not sltb.EOF do
  begin
    Result.Add(sltb.FieldAsString(sltb.FieldIndex['ValKey']));
    sltb.Next;
  end;

  if sltb <> nil then
    FreeAndNil(sltb);

end;

function TdesktopDb.GetString(ValName: string): string;
var
  sltb: TSQLIteTable;
begin

  sltb := sldb.GetTable('select Value from desktopdb where ValKey=''' + ValName + '''');
  sltb.MoveFirst;
  if sltb.Count > 0 then
    Result := (sltb.FieldAsString(sltb.FieldIndex['Value']));

  if sltb <> nil then
    FreeAndNil(sltb);
end;

procedure TdesktopDb.SetVarValue(ValName: string; val: Variant);
var
  SQL: string;
  c: Integer;
begin

  sltb := sldb.GetTable(Format('select count(*) as co from desktopdb where ValKey=''%s''', [ValName]));

  sltb.MoveFirst;
  if sltb.Count > 0 then
    c := (sltb.FieldAsInteger(sltb.FieldIndex['co']));
  if c = 0 then
  begin
    SQL := Format('Insert Into desktopdb(ValKey, Value) Values(''%s'', ''%s'')', [ValName, val])
  end
  else
  begin
    SQL := Format('update desktopdb Set Value=''%s'' where ValKey=''%s''', [val, ValName]);

  end;
  try
    sldb.BeginTransaction;
    sldb.execsql(SQL);
    sldb.Commit;
  except
    sldb.RollBack;
  end;
end;

initialization
  if sldb = nil then
    sldb := TSQLiteDatabase.Create(ExtractFilepath(ParamStr(0)) + 'DestTopdb.db');


finalization
  if g_core.db.cfgDb <> nil then
    FreeAndNil(g_core.db.cfgDb);

  if g_core.db.itemdb <> nil then
    FreeAndNil(g_core.db.itemdb);

end.

