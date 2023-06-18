# Wx::SF base definitions
# Copyright (c) M.J.N. Corino, The Netherlands

module Wx::SF

  class SFException < ::Exception; end

  RECURSIVE = true
  NORECURSIVE = false
  DIRECT = true
  INDIRECT = false
  WITHCHILDREN = true
  WITHOUTCHILDREN = false
  ANY = nil
  DELAYED = true
  ACCEPT_ALL = :*

  INCLUDE_PARENTS = true
  WITHOUT_PARENTS = false
  INITIALIZE = true
  DONT_INITIALIZE = false

  DEFAULT_ME_OFFSET = 5
  SAVE_STATE = true
  DONT_SAVE_STATE = false
  FROM_PAINT = true
  NOT_FROM_PAINT = false
  PROMPT = true
  NO_PROMPT = false
  WITH_BACKGROUND = true
  WITHOUT_BACKGROUND = false

end
