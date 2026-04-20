<?php
// Exit if accessed directly
if (!defined('ABSPATH')) {
    die('Un-authorized access!');
}

class Privyr_Bricks_Form
{
    /**
     * Extract form field values from the Bricks form submission
     * and build a key-value payload using field labels as keys.
     */
    private function format_fields_payload($form)
    {
        $form_settings = $form->get_settings();
        $form_fields   = $form->get_fields();
        $fields_config = isset($form_settings['fields']) ? $form_settings['fields'] : array();

        $body = array();

        foreach ($fields_config as $field) {
            $field_id   = isset($field['id']) ? $field['id'] : '';
            $field_type = isset($field['type']) ? $field['type'] : '';

            // Skip non-value fields
            if (empty($field_id) || in_array($field_type, array('file', 'html'), true)) {
                continue;
            }

            // Skip honeypot fields
            if (isset($field['isHoneypot'])) {
                continue;
            }

            // Use label as key, fall back to type_id
            $key = !empty($field['label']) ? $field['label'] : $field_type . '_' . $field_id;

            $value = isset($form_fields["form-field-{$field_id}"]) ? $form_fields["form-field-{$field_id}"] : '';

            // Handle array values (e.g. checkbox)
            if (is_array($value)) {
                $value = implode(', ', $value);
            }

            // Mask password fields
            if ($field_type === 'password') {
                $value = '********';
            }

            $body[$key] = $value;
        }

        return $body;
    }

    /**
     * Bricks form "Custom" action callback.
     * Hooks into bricks/form/custom_action to send lead data to Privyr.
     */
    public function submit_bricks_form_to_privyr($form)
    {
        // Build a form name from the post title + form element ID
        $post_id   = $form->get_post_id();
        $form_id   = $form->get_id();
        $form_name = get_the_title($post_id) . ' (#' . $form_id . ')';

        // Reuse the Elementor form endpoint — same FORM_URLENCODED payload format
        $privyr_api = new Privyr_API('bricks_form', $form_name);
        $endpoint   = $privyr_api->build_api_endpoint();
        $payload    = $this->format_fields_payload($form);
        $payload['form_name'] = $form_name;

        $privyr_api->submit_lead_to_privyr($endpoint, $payload, Content_Type::FORM_URLENCODED);
    }
}
