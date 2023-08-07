(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_consts;

interface

uses
Messages;

const

  CURRENT_PROJECT_VERSION = 5;

  PARAMETERS_FILE_NAME = 'params.dsc';
  PROJECT_FILE_NAME = 'project.dsc';

  WM_RECALC = WM_USER + 1;
  WM_STARTEDITING = WM_USER + 2;

  PAlias : array [1..3] of string = ('H','s','r');


  APPDATA_DIR_NAME = 'X-Ray Calc3';
  SETTINGS_FILE_NAME = 'xrc3.ini';
  APP_HELP_FILENAME = 'xraycalc3.chm';
  VERINFO_FILENAME = 'version.info';
  LICENSE_FILENAME = 'xraycalc3.lic';
  DEFAULT_PROJECT_NAME = 'NewProject.xrcx';
implementation

end.
