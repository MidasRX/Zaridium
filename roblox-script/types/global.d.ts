declare const VERSION: string;

/*
 * Executor globals (UNC / sUNC). Everything is optional because the script
 * also runs in Studio, where none of these exist.
 */
declare const getgenv: (() => Record<string, unknown>) | undefined;
declare const gethui: (() => BasePlayerGui) | undefined;
declare const loadstring: (source: string, chunkname?: string) => LuaTuple<[Callback | undefined, string | undefined]>;
declare const request: ((options: RequestAsyncRequest) => RequestAsyncResponse) | undefined;
declare const queue_on_teleport: ((script: string) => void) | undefined;
declare const makefolder: ((path: string) => void) | undefined;
declare const isfolder: ((path: string) => boolean) | undefined;
declare const isfile: ((path: string) => boolean) | undefined;
declare const readfile: ((path: string) => string) | undefined;
declare const writefile: ((path: string, content: string) => void) | undefined;

interface DataModel {
	HttpGetAsync(url: string, requestType?: Enum.HttpRequestType): string;
	HttpPostAsync(url: string, data: string, contentType?: string, requestType?: Enum.HttpRequestType): string;
}