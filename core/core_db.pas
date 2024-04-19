unit core_db;

interface

uses
  SysUtils, SQLiteTable3, Classes, System.Generics.Collections;

type
  TGenericDB<T> = class
  protected
    function GetInternalString(tableName, ValName: string): string;
    procedure SetInternalValue(tableName, ValName: string; val: Variant);
    function GetInternalKeys(tableName: string): TList<string>;
  end;

  TdesktopDb = class(TGenericDB<string>)
  public
    function GetString(ValName: string): string;
    procedure SetVarValue(ValName: string; val: Variant);
    procedure DeleteValue(ValName: string);
    function GetKeys(): TList<string>;
    procedure Clean();
    constructor Create();
    destructor Destroy; override;
  end;

  TItemsDb = class(TGenericDB<boolean>)
  public
    function GetString(ValName: string; keyflag: boolean = true): string;
    procedure SetVarValue(ValName: string; val: Variant; keyflag: boolean = true);
    procedure DeleteValue(ValName: string; keyflag: boolean = true);
    function GetKeys(keyflag: boolean = true): TList<string>;
    procedure Clean(keyflag: boolean = true);
    constructor Create();
    destructor Destroy; override;
  end;

  TCfgDB = class(TGenericDB<string>)
  public
    function GetString(ValName: string): string;
    function GetInteger(ValName: string): Integer;
    function GetBoolean(ValName: string; ADefault: boolean = false): boolean;
    procedure SetVarValue(ValName: string; val: Variant);
    procedure SetValue(ValName: string; val: string); overload;
    procedure SetValue(ValName: string; val: Integer); overload;
    procedure SetValue(ValName: string; val: boolean); overload;
    procedure SetValue(ValName: string; val: Double); overload;
    procedure DeleteValue(ValName: string);
    function GetKeys(AKey: string): string;
    constructor Create();
    destructor Destroy; override;
  end;

  TGDB = record
    cfgDb: TCfgDB;
    itemDb: TItemsDb;
    desktopDb: TdesktopDb;
  end;

var
  sldb: TSQLiteDatabase;

implementation

{ TGenericDB<T> }

function TGenericDB<T>.GetInternalString(tableName, ValName: string): string;
var
  Query: string;
begin
  Query := Format('SELECT Value FROM %s WHERE ValKey = ''%s''', [tableName, ValName]);
 var sltb := sldb.GetTable(Query);
  try
    if not sltb.EOF then
      Result := sltb.FieldAsString(sltb.FieldIndex['Value'])
    else
      Result := '';
  finally
    sltb.Free;
  end;
end;

procedure TGenericDB<T>.SetInternalValue(tableName, ValName: string; val: Variant);
var
  SQL: string;
begin
  if GetInternalString(tableName, ValName) <> '' then
    SQL := Format('UPDATE %s SET Value = ''%s'' WHERE ValKey = ''%s''', [tableName, val, ValName])
  else
    SQL := Format('INSERT INTO %s(ValKey, Value) VALUES (''%s'', ''%s'')', [tableName, ValName, val]);

  try
    sldb.ExecSQL(SQL);
  except
    // Handle exceptions here
  end;
end;

function TGenericDB<T>.GetInternalKeys(tableName: string): TList<string>;
var
  Query: string;
begin
  Query := Format('SELECT ValKey FROM %s', [tableName]);
 var sltb := sldb.GetTable(Query);
  try
    Result := TList<string>.Create;
    while not sltb.EOF do
    begin
      Result.Add(sltb.FieldAsString(sltb.FieldIndex['ValKey']));
      sltb.Next;
    end;
  finally
    sltb.Free;
  end;
end;

{ TdesktopDb }

constructor TdesktopDb.Create;
const
  FInitSQL = 'CREATE TABLE IF NOT EXISTS desktopdb(ID INTEGER PRIMARY KEY, ' +
              'ValKey VARCHAR(50) COLLATE NOCASE, Value VARCHAR(400) COLLATE NOCASE);' +
              'CREATE INDEX IF NOT EXISTS idx_desktopdb_ValKey ON desktopdb(ValKey)';
begin
  inherited;
  sldb.ExecSQL(FInitSQL);
end;

destructor TdesktopDb.Destroy;
begin
  inherited;
end;

procedure TdesktopDb.Clean;
begin
  sldb.ExecSQL('DELETE FROM desktopdb');
end;

procedure TdesktopDb.DeleteValue(ValName: string);
begin
  sldb.ExecSQL(Format('DELETE FROM desktopdb WHERE ValKey = ''%s''', [ValName]));
end;

function TdesktopDb.GetKeys: TList<string>;
begin
  Result := GetInternalKeys('desktopdb');
end;

function TdesktopDb.GetString(ValName: string): string;
begin
  Result := GetInternalString('desktopdb', ValName);
end;

procedure TdesktopDb.SetVarValue(ValName: string; val: Variant);
begin
  SetInternalValue('desktopdb', ValName, val);
end;

{ TItemsDb }

constructor TItemsDb.Create;
const
  FInitKeysSQL = 'CREATE TABLE IF NOT EXISTS keysdb(ID INTEGER PRIMARY KEY, ' +
                 'ValKey VARCHAR(50) COLLATE NOCASE, Value VARCHAR(400) COLLATE NOCASE);' +
                 'CREATE INDEX IF NOT EXISTS idx_keysdb_ValKey ON keysdb(ValKey)';
  FInitValuesSQL = 'CREATE TABLE IF NOT EXISTS valuesdb(ID INTEGER PRIMARY KEY, ' +
                   'ValKey VARCHAR(50) COLLATE NOCASE, Value VARCHAR(400) COLLATE NOCASE);' +
                   'CREATE INDEX IF NOT EXISTS idx_valuesdb_ValKey ON valuesdb(ValKey)';
begin
  inherited;
  sldb.ExecSQL(FInitKeysSQL);
  sldb.ExecSQL(FInitValuesSQL);
end;

destructor TItemsDb.Destroy;
begin
  inherited;
end;

procedure TItemsDb.Clean(keyflag: boolean);
begin
  if keyflag then
    sldb.ExecSQL('DELETE FROM keysdb')
  else
    sldb.ExecSQL('DELETE FROM valuesdb');
end;

procedure TItemsDb.DeleteValue(ValName: string; keyflag: boolean);
begin
  if keyflag then
    sldb.ExecSQL(Format('DELETE FROM keysdb WHERE ValKey = ''%s''', [ValName]))
  else
    sldb.ExecSQL(Format('DELETE FROM valuesdb WHERE ValKey = ''%s''', [ValName]));
end;

function TItemsDb.GetKeys(keyflag: boolean): TList<string>;
begin
  if keyflag then
    Result := GetInternalKeys('keysdb')
  else
    Result := GetInternalKeys('valuesdb');
end;

function TItemsDb.GetString(ValName: string; keyflag: boolean): string;
begin
  if keyflag then
    Result := GetInternalString('keysdb', ValName)
  else
    Result := GetInternalString('valuesdb', ValName);
end;

procedure TItemsDb.SetVarValue(ValName: string; val: Variant; keyflag: boolean);
begin
  if keyflag then
    SetInternalValue('keysdb', ValName, val)
  else
    SetInternalValue('valuesdb', ValName, val);
end;

{ TCfgDB }

constructor TCfgDB.Create;
const
  FInitSQL = 'CREATE TABLE IF NOT EXISTS SysProfile(ID INTEGER PRIMARY KEY, ' +
              'ValKey VARCHAR(50) COLLATE NOCASE, Value VARCHAR(400) COLLATE NOCASE);' +
              'CREATE INDEX IF NOT EXISTS idx_SysProfile_ValKey ON SysProfile(ValKey)';
begin
  inherited;
  sldb.ExecSQL(FInitSQL);
end;

destructor TCfgDB.Destroy;
begin
  inherited;
end;

procedure TCfgDB.DeleteValue(ValName: string);
begin
  sldb.ExecSQL(Format('DELETE FROM SysProfile WHERE ValKey = ''%s''', [ValName]));
end;

function TCfgDB.GetBoolean(ValName: string; ADefault: boolean): boolean;
var
  r: string;
begin
  Result := ADefault;
  r := GetString(ValName);
  if r <> '' then
    Result := UpperCase(r) <> 'FALSE';
end;

function TCfgDB.GetInteger(ValName: string): Integer;
var
  r: string;
begin
  Result := 0;
  r := GetString(ValName);
  if r <> '' then
    Result := StrToIntDef(r, 0);
end;

function TCfgDB.GetKeys(AKey: string): string;
begin
 var sltb := sldb.GetTable(Format('SELECT ValKey FROM SysProfile WHERE ValKey LIKE ''%s%%'' ORDER BY ID ASC', [AKey]));
  try
    if not sltb.EOF then
      Result := sltb.FieldAsString(sltb.FieldIndex['ValKey'])
    else
      Result := '';
  finally
    sltb.Free;
  end;
end;

function TCfgDB.GetString(ValName: string): string;
begin
  Result := GetInternalString('SysProfile', ValName);
end;

procedure TCfgDB.SetVarValue(ValName: string; val: Variant);
begin
  SetInternalValue('SysProfile', ValName, val);
end;

procedure TCfgDB.SetValue(ValName, val: string);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetValue(ValName: string; val: Integer);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetValue(ValName: string; val: Double);
begin
  SetVarValue(ValName, val);
end;

procedure TCfgDB.SetValue(ValName: string; val: boolean);
begin
  SetVarValue(ValName, val);
end;

initialization
  if sldb = nil then
    sldb := TSQLiteDatabase.Create(ExtractFilePath(ParamStr(0)) + 'UserSettingsDB.db');


finalization
  sldb.Free;

end.

