// https://docs.cypress.io/api/introduction/api.html

describe("Actor flow", () => {
  it("Joins a production", () => {
    cy.visit("/");
    cy.get("ion-button", {
      timeout: 30000
    })
      .contains("Henry IV: Act 5.json")
      .wait()
      .click({ force: true });
    cy.get();
  });
});
