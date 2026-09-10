(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

unit unit_MCPUnits;

(* Unit conversions shared by every tool that takes a wavelength.

   The server speaks Angstrom for wavelength and length, eV for photon energy
   and degrees for angles, and every angle argument is the *incidence* angle
   theta, never 2-theta. A tool that wants to accept a diffractometer reading
   converts it with TwoThetaToTheta first.

   Two conversion constants are in play and they are not the same number.
   HC_EV_ANGSTROM (12398.42) is the value the requirements fix for the
   energy/wavelength conversion the server exposes to clients. ENGINE_HC
   (12398.6) is math_globals.H, the constant the calculation engines use
   internally when they look a material up in the Henke tables. The difference
   is 1.4e-5 relative - far below any experimental resolution - but the two are
   kept separate rather than silently unified: describe_server reports both, so
   a client comparing our numbers with its own never has to guess. *)

interface

uses System.JSON;

const
  HC_EV_ANGSTROM = 12398.42;   // requirements 2.4: the server's E <-> lambda constant
  ENGINE_HC      = 12398.6;    // math_globals.H, used by the engines for table lookup

/// <summary>Photon energy in eV to wavelength in Angstrom.
/// Raises EMCPError('invalid_argument') for a non-positive energy.</summary>
function EnergyToLambda(EeV: Double): Double;
/// <summary>Wavelength in Angstrom to photon energy in eV.
/// Raises EMCPError('invalid_argument') for a non-positive wavelength.</summary>
function LambdaToEnergy(LambdaA: Double): Double;
/// <summary>Scattering angle 2-theta to incidence angle theta, in the same
/// unit (the server uses degrees).</summary>
function TwoThetaToTheta(TwoTheta: Double): Double;
/// <summary>The wavelength an argument object asks for, in Angstrom. Exactly
/// one of LambdaKey and EnergyKey must be present: both is ambiguous and
/// neither is under-specified, and each raises
/// EMCPError('invalid_argument'). When AllowMissing is True, neither present
/// returns Default instead of raising.</summary>
function GetLambdaArg(const P: TJSONObject; const LambdaKey: string = 'lambda';
  const EnergyKey: string = 'energy'; AllowMissing: Boolean = False;
  Default: Double = 0): Double;

implementation

uses System.SysUtils, unit_MCPErrors;

function EnergyToLambda(EeV: Double): Double;
begin
  if EeV <= 0 then
    raise EMCPError.Create('invalid_argument',
      'Photon energy must be greater than zero eV', FloatToStr(EeV));
  Result := HC_EV_ANGSTROM / EeV;
end;

function LambdaToEnergy(LambdaA: Double): Double;
begin
  if LambdaA <= 0 then
    raise EMCPError.Create('invalid_argument',
      'Wavelength must be greater than zero Angstrom', FloatToStr(LambdaA));
  Result := HC_EV_ANGSTROM / LambdaA;
end;

function TwoThetaToTheta(TwoTheta: Double): Double;
begin
  Result := TwoTheta / 2;
end;

function GetLambdaArg(const P: TJSONObject; const LambdaKey: string;
  const EnergyKey: string; AllowMissing: Boolean; Default: Double): Double;
var
  HasLambda, HasEnergy: Boolean;
  L: Double;
begin
  HasLambda := JSONArgs.Has(P, LambdaKey);
  HasEnergy := JSONArgs.Has(P, EnergyKey);

  if HasLambda and HasEnergy then
    raise EMCPError.Create('invalid_argument',
      Format('Give either "%s" or "%s", not both', [LambdaKey, EnergyKey]));

  if HasLambda then
  begin
    L := JSONArgs.ReqFloat(P, LambdaKey);
    if L <= 0 then
      raise EMCPError.Create('invalid_argument',
        Format('"%s" must be greater than zero Angstrom', [LambdaKey]), FloatToStr(L));
    Exit(L);
  end;

  if HasEnergy then
    Exit(EnergyToLambda(JSONArgs.ReqFloat(P, EnergyKey)));

  if AllowMissing then
    Exit(Default);

  raise EMCPError.Create('invalid_argument',
    Format('Give either "%s" (Angstrom) or "%s" (eV)', [LambdaKey, EnergyKey]));
end;

end.
