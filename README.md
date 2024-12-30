# playground-axios-aws-v4-signature

A demo app that uses AWS Signature V4 for Auth

There are three parts to this project:

- /app - the HTTP lambda that gets deployed by terraform
- /infrastructure - the infrastructure which (also deploys the /app lambda)
- /acceptance-tests - the tests that exercise the AWS Signature V4 code

## Instructions

Install any missing NPM packages:

```bash
npm ci
```

Deploy the lambda and get the API Gateway URL. For var.iam_user_arn use a role you've created and been added to:

```bash
cd infrastructure

awsume <your_role_here>

terraform init

terraform apply --var environment=test --var iam_user_arn=<your_role_here>
```

Take the `domain_name` value and shove it into the first part of the domain in [acceptance-tests/endpoint.test.ts](acceptance-tests/endpoint.test.ts)

```typescript
const sut = new ExampleClient({
  baseUrl: "PUT_YOUR_DOMAIN_HERE",
  accessKeyId: config.AWS_ACCESS_KEY_ID,
  region: "eu-west-1",
  secretAccessKey: config.AWS_SECRET_ACCESS_KEY,
  sessionToken: config.AWS_SESSION_TOKEN,
});
```

## Bruno

There is an example [Bruno](https://www.usebruno.com/) collection in this project at ./bruno with an example AWS Sig V4 setup.

Add the collection to your Bruno client to use it. Remember to never save anything sensitive and to use Environment variables and secrets.

![Bruno Collection](bruno-collection.png)
