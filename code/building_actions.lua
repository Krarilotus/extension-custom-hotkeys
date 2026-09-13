local A=require('code/addresses')
-- Original H/G/A/B/M/I/T/N shortcuts share the native status opener, with
-- separate camera bookmarks. Addresses are reference SHC1.41 player ID fields.
-- These are existing-building actions, distinct from placement choices.
return {
  {name='keep',scan=35,types={40,41,42,43,44},reference=A.playerKeep,bookmark=A.keepBookmark,text=7},
  {name='granary',scan=34,types={19},reference=A.playerGranary,bookmark=A.granaryBookmark,text=46},
  {name='armory',scan=30,types={11},reference=A.playerArmory,bookmark=A.armoryBookmark,text=8,focusMods=4},
  {name='barracks',scan=48,types={9},reference=A.playerBarracks,bookmark=A.barracksBookmark,text=10},
  {name='market',scan=50,types={26},reference=A.playerMarket,bookmark=A.marketBookmark,text=49},
  {name='engineers-guild',scan=23,types={24},reference=A.playerEngineersGuild,bookmark=A.engineersBookmark,text=66},
  {name='tunnelers-guild',scan=20,types={25},reference=A.playerTunnelersGuild,bookmark=A.tunnelersBookmark,text=67},
  {name='mercenary-post',scan=49,types={8},reference=A.playerMercenaryPost,bookmark=A.mercenaryBookmark,text=9},
  {name='stockpile',types={10},reference=A.playerStockpile,text=45},
}
