export const handler = async (event, context) => {
  return {
    statusCode: 200,
    body: JSON.stringify([
      { id: 1, name: "First" },
      { id: 2, name: "Second" },
      { id: 3, name: "Third" },
    ]),
  };
};
