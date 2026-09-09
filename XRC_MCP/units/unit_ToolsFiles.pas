unit unit_ToolsFiles;

(* The file tools: the measurement inbox now, the .xrcx project tools later.

   Both inbox tools are read-only, and deliberately so: inbox\ holds the
   experimental data, the one thing in the work directory the server has no
   business changing. list_measurements says what is there and what its SHA-256
   is, get_measurement hands the parsed curve back, and neither ever opens a
   file for writing. *)

interface

uses unit_MCPTools;

procedure RegisterFileTools(Registry: TToolRegistry);

implementation

uses
  System.JSON,
  unit_MCPErrors, unit_MCPInbox;

procedure RegisterInboxTools(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Schema := SchemaObject([]);
  AddProp(Schema, 'specimen', 'string',
    'List only this specimen folder (exact name, case-insensitive). ' +
    'Omit to list every specimen in the inbox.');
  Registry.Register('list_measurements',
    'Lists the measured curves waiting in the inbox. The inbox is one folder per ' +
    'specimen under inbox\, and each file in it is a measurement identified by ' +
    '"<specimen>/<file>" - the measurement_id get_measurement and fit_xrr take. ' +
    'For every file the name, id, size, SHA-256 and last-modified time are ' +
    'reported, together with the contents of the specimen''s meta.json when it ' +
    'has one. A specimen whose meta.json cannot be read is still listed, with ' +
    '"meta": null and a "meta_error" saying what is wrong with it, so that one ' +
    'bad file never hides the rest of the inbox. Files lying loose in inbox\ ' +
    'rather than in a specimen folder have no id and are only counted, as ' +
    '"loose_files". Nothing here is ever written.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := ListMeasurementsJSON(JSONArgs.OptStr(Params, 'specimen', ''));
    end);

  Schema := SchemaObject(['measurement_id']);
  AddProp(Schema, 'measurement_id', 'string',
    'The measurement to read, as "<specimen>/<file>" exactly as list_measurements ' +
    'reports it. The file extension must be .dat, .txt or .xy.');
  AddProp(Schema, 'max_points', 'integer',
    'Decimate the curve to at most this many points before returning it ' +
    '(default 2000; minimum 2; first and last points are always kept). ' +
    '"points" is the number in the file and "points_returned" the number returned.');
  Registry.Register('get_measurement',
    'Reads one measured curve from the inbox and returns it as [theta, intensity] ' +
    'pairs. The file is parsed the way the X-Ray Calc 3 GUI parses it: two ' +
    'columns separated by a tab or a space, a comma accepted as the decimal mark, ' +
    'non-numeric lines returned as "header", and a non-positive intensity ' +
    'replaced by the smallest positive one seen so far. When the specimen''s ' +
    'meta.json says "theta_unit": "2theta" every angle is halved, so the curve ' +
    'returned is always theta in degrees, and "converted_from_2theta" says ' +
    'whether that happened; when meta.json does not say, theta is assumed and ' +
    '"theta_unit_assumed" is true. The file is opened read-only and is never modified.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := GetMeasurementJSON(JSONArgs.ReqStr(Params, 'measurement_id'),
        JSONArgs.OptInt(Params, 'max_points', DEFAULT_MAX_POINTS));
    end);
end;

procedure RegisterFileTools(Registry: TToolRegistry);
begin
  RegisterInboxTools(Registry);
  // The .xrcx project tools are added in a later task.
end;

end.
