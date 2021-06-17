// https://docs.cypress.io/api/introduction/api.html

describe("Director flow", () => {
  it("Makes a production", () => {
    cy.visit("/");

    cy.get("#make-new-production").click();
    cy.get("ion-item")
      .contains("Henry IV: Act 5.json")
      .click({ force: true });
    cy.get("#begin-show", {
      timeout: 10000
    })
      .wait()
      .click();
  });
});
