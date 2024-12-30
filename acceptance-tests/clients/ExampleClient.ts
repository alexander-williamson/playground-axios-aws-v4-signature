import aws4Interceptor from "aws4-axios";
import axios, { AxiosInstance } from "axios";

export class ExampleClient implements IExampleClient {
  private axiosInstance: AxiosInstance;

  constructor(options: Options) {
    this.axiosInstance = axios.create({
      baseURL: options.baseUrl,
    });
    const interceptor = aws4Interceptor({
      options: {
        region: options.region,
        service: "execute-api",
      },
      credentials: {
        accessKeyId: options.accessKeyId,
        secretAccessKey: options.secretAccessKey,
        sessionToken: options.sessionToken,
      },
    });
    this.axiosInstance.interceptors.request.use(interceptor);
  }

  public async postExample(data: PostExampleRequestBody): Promise<PostExampleResponseBody> {
    const result = await this.axiosInstance({
      url: "/v1/users",
      method: "POST",
      data,
    });
    return result.data as PostExampleResponseBody;
  }
}

export interface IExampleClient {
  postExample(data: PostExampleRequestBody): Promise<PostExampleResponseBody>;
}

export type PostExampleRequestBody = { message: string };
export type PostExampleResponseBody = { id: string; name: string }[];

export type Options = {
  baseUrl: string;
  region: string;
  accessKeyId: string;
  secretAccessKey: string;
  sessionToken?: string;
};
