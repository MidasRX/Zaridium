-- Type declarations for executor globals (UNC / sUNC). Used only by `luau-analyze`; never shipped.
-- Every function is optional because executors differ and Roblox Studio has none of them.

declare getgenv: (() -> { [string]: any })?
declare gethui: (() -> Instance)?
declare getcustomasset: ((path: string, noCache: boolean?) -> string)?
declare writefile: ((path: string, content: string) -> ())?
declare readfile: ((path: string) -> string)?
declare isfile: ((path: string) -> boolean)?
declare isfolder: ((path: string) -> boolean)?
declare makefolder: ((path: string) -> ())?
declare listfiles: ((path: string) -> { string })?
declare delfile: ((path: string) -> ())?
declare setclipboard: ((text: string) -> ())?
declare queue_on_teleport: ((code: string) -> ())?
declare cloneref: ((instance: Instance) -> Instance)?
declare identifyexecutor: (() -> (string, string?))?
declare protectgui: ((instance: Instance) -> ())?