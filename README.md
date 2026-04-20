# Privyr CRM – Bricks Builder Integration Patcher

This repository contains a patcher that extends the official Privyr CRM Integration plugin to natively support [Bricks Builder](https://bricksbuilder.io/) form submissions.

> [!IMPORTANT]
> This patcher is explicitly designed and tested for `privy-crm-integration` version **v1.0.3**. Using it on other versions may cause patch failures if the core files have changed.

## What it does

The script seamlessly injects Bricks Builder support into the Privyr CRM plugin by:
1. Copying the `Privyr_Bricks_Form` integration class and a Bricks logo to the plugin directories.
2. Applying standard unified diff patches to cleanly update `class-privyr-crm.php` (to load the class and register the hook) and `class-privyr-crm-constants.php` (to register the integration layout).
3. Instantiating a native block in the WordPress admin panel allowing you to toggle the Bricks Builder integration identical to standard integrations like WPForms or Contact Form 7.

## Why is a patcher needed?

The Privyr plugin does **not** natively expose WordPress developer hooks (filters/actions) that would allow an external plugin to register a new form type or integration dynamically. 

1. The `SUPPORTED_INTEGRATIONS` list is an entirely hardcoded `const array`.
2. Form endpoints and plugin state flags are explicitly retrieved using exact matching identifiers within that array.
3. The method defining all form integration hooks (`define_integration_hooks`) instantiates them sequentially inside the core class, with no dynamic injection mechanism.

As a result, building an external "bridge" plugin wouldn't work seamlessly because the user interface, integration status checks, and settings pages within Privyr wouldn't have access to the Bricks identifier. Patching the plugin natively is the only robust approach to utilizing the plugin without rewriting Privyr's entire core logic and token authentication flow from scratch.

## Why use the Elementor endpoint?

Every form plugin officially supported by Privyr features a dedicated webhook URL endpoint on Privyr's backend server (e.g., `/api/v1/wpforms-webhook`, `/api/v1/gravity-form-webhook`). 

If we pointed the Bricks integration to a hypothetical `/api/v1/bricks-form-webhook`, Privyr's backend would immediately reject the connection with a `404 Not Found` error because the endpoint hasn't been programmed on their routing architecture. 

However, both Elementor Pro Forms and Bricks Builder structure their payload identically: exporting form data using native `application/x-www-form-urlencoded` format mapped to field labels and values. By elegantly routing Bricks Builder submissions through the existing `elementor-form-webhook` endpoint, the lead transmission processes cleanly and flawlessly without breaking data constraints.

## How to use

1. Ensure the official `privy-crm-integration` plugin is placed in the required destination folder.
2. Open your terminal and navigate to the root directory where the `patcher` folder resides.
3. Run the shell script:

```bash
cd patcher
./apply-patch.sh ../path-to-your-privy-plugin-folder
```
*(Note: If no path is provided, the script strictly defaults to searching for `../privy-crm-integration` relative to the script location)*

### Configuring the Form in Bricks Builder

Once patched, your Bricks form demands slightly specialized configuration:
1. Open the relevant page in Bricks Builder.
2. Select your specific **Form Element**.
3. Under the **Actions** dropdown menu, explicitly select **Custom**.
4. Save the page. The newly patched Privyr CRM plugin will instantly hook into this native `bricks/form/custom_action` trigger and securely forward your parsed lead data to Privyr.
