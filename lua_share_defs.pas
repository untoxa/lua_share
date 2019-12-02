{$ifdef FPC}
  {$mode DELPHI}
{$else}
  {$define MSWINDOWS}
{$endif}

{$define release}
{$define enable_logging}

{$ifdef release}
  {$undef enable_logging}
  {$d-}
{$endif}
