const navToggle = document.querySelector("[data-nav-toggle]");
const navPanel = document.querySelector("[data-nav-panel]");

if (navToggle && navPanel) {
  navToggle.addEventListener("click", () => {
    const isOpen = navPanel.classList.toggle("is-open");
    navToggle.setAttribute("aria-expanded", String(isOpen));
  });

  navPanel.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      navPanel.classList.remove("is-open");
      navToggle.setAttribute("aria-expanded", "false");
    });
  });
}

const mailtoLinks = document.querySelectorAll("[data-mailto][data-subject]");

mailtoLinks.forEach((link) => {
  const email = link.getAttribute("data-mailto");
  const subject = link.getAttribute("data-subject");

  if (!email || !subject) {
    return;
  }

  link.setAttribute("href", `mailto:${email}?subject=${encodeURIComponent(subject)}`);
});

const revealNodes = document.querySelectorAll("[data-reveal]");

if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    {
      threshold: 0.18,
      rootMargin: "0px 0px -4% 0px",
    }
  );

  revealNodes.forEach((node) => observer.observe(node));
} else {
  revealNodes.forEach((node) => node.classList.add("is-visible"));
}
