import { HttpService } from "@rbxts/services";
import { IS_DEV } from "constants";

const executorRequest = request;

async function sendRequest(requestOptions: RequestAsyncRequest): Promise<RequestAsyncResponse> {
	if (IS_DEV) {
		return HttpService.RequestAsync(requestOptions);
	}
	if (!executorRequest) {
		throw "request is not available";
	}
	return executorRequest(requestOptions);
}

export { sendRequest as request };

export async function get(url: string, requestType?: Enum.HttpRequestType): Promise<string> {
	return game.HttpGetAsync(url, requestType);
}

export async function post(
	url: string,
	data: string,
	contentType?: string,
	requestType?: Enum.HttpRequestType,
): Promise<string> {
	return game.HttpPostAsync(url, data, contentType, requestType);
}
