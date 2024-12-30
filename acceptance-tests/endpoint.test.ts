import { ExampleClient } from "./clients/ExampleClient";
import joi from "joi";
import "dotenv/config";

const { value: config, error } = joi
  .object({
    AWS_ACCESS_KEY_ID: joi.string().required(),
    AWS_SECRET_ACCESS_KEY: joi.string().required(),
    AWS_SESSION_TOKEN: joi.string().required(),
  })
  .unknown()
  .required()
  .validate(process.env);

if (error) {
  throw error;
}

describe("client", () => {
  describe("postExample", () => {
    it("returns values from the example endpoint", async () => {
      const sut = new ExampleClient({
        baseUrl: "https://qbyf2fes7c.execute-api.eu-west-1.amazonaws.com/default",
        accessKeyId: config.AWS_ACCESS_KEY_ID,
        region: "eu-west-1",
        secretAccessKey: config.AWS_SECRET_ACCESS_KEY,
        sessionToken: config.AWS_SESSION_TOKEN,
      });

      const data = { message: "hello world" };
      const result = await sut.postExample(data);

      expect(result).toEqual([
        { id: 1, name: "First" },
        { id: 2, name: "Second" },
      ]);
    });
  });
});
