ActiveAdmin.register_page "ApiToken" do
  menu parent: "Settings", label: "API Tokens"

  FILE_PATH = Rails.root.join("public", "skumonster", "api_tokens.yml")

  content do
    file_data = YAML.load_file(FILE_PATH) rescue {}
    file_data ||= {}

    panel "API Tokens" do
      active_admin_form_for :api_info, url: admin_api_token_update_path, method: :post, as: :api_info do |f|
        f.inputs do
          value = file_data["token"] rescue ''

          div do
            text_node <<~HTML.html_safe
              <div style="display:flex; align-items:center; gap:10px;">
                <input type="password" id="api_token" value="#{value}" readonly style="width:500px;"/>
                <i id="toggle_token"
                   class="bi bi-eye-slash"
                   style="cursor:pointer;font-size:18px;color:#666;margin-left:-35px;"
                   title="Show / Hide Token">
                </i>

                <button type="button" id="copy_token" style="padding:5px 10px;cursor:pointer;">
                  Copy
                </button>
              </div>

              <script>
                (function () {
                  function initTokenControls() {
                    const tokenField = document.getElementById("api_token");
                    const toggleBtn = document.getElementById("toggle_token");
                    const copyBtn = document.getElementById("copy_token");

                    if (!tokenField || !toggleBtn) return;

                    toggleBtn.onclick = function () {
                      const hidden = tokenField.type === "password";

                      tokenField.type = hidden ? "text" : "password";

                      // toggle icon safely
                      toggleBtn.classList.toggle("bi-eye");
                      toggleBtn.classList.toggle("bi-eye-slash");
                    };

                    if (copyBtn) {
                      copyBtn.onclick = function () {
                        navigator.clipboard.writeText(tokenField.value);

                        const old = copyBtn.innerText;
                        copyBtn.innerText = "Copied!";

                        setTimeout(function () {
                          copyBtn.innerText = old;
                        }, 1200);
                      };
                    }
                  }

                  if (document.readyState === "loading") {
                    document.addEventListener("DOMContentLoaded", initTokenControls);
                  } else {
                    initTokenControls();
                  }
                })();
              </script>
            HTML
          end
        end
        f.actions do
          f.action :submit, label: "Generate New Token"
        end
      end
    end
  end
end
