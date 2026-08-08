use embedrelay_space_contract::{RelayIdentifier, RelayIdentifierParseError};
use uuid::{Variant, Version};

const RFC_9562_V7_VECTOR: &str = "017F22E2-79B0-7CC3-98C4-DC0C0C07398F";

#[test]
fn rfc_9562_uuid_v7_vector_round_trips_canonically() {
    let identifier = RelayIdentifier::parse(RFC_9562_V7_VECTOR).expect("RFC 9562 vector is valid");

    assert_eq!(
        identifier.to_string(),
        "017f22e2-79b0-7cc3-98c4-dc0c0c07398f"
    );
    assert_eq!(identifier.as_uuid().get_version(), Some(Version::SortRand));
    assert_eq!(identifier.as_uuid().get_variant(), Variant::RFC4122);
}

#[test]
fn generated_identifiers_are_ordered_uuid_v7_values() {
    let first = RelayIdentifier::new();
    let second = RelayIdentifier::new();

    assert!(first < second);
    assert_eq!(first.as_uuid().get_version_num(), 7);
    assert_eq!(second.as_uuid().get_variant(), Variant::RFC4122);
}

#[test]
fn parser_rejects_non_uuid_input_without_reflecting_it() {
    let error = RelayIdentifier::parse("customer-controlled-secret").expect_err("invalid UUID must fail");

    assert_eq!(error, RelayIdentifierParseError::InvalidUuid);
    assert_eq!(error.to_string(), "identifier must be a valid UUID");
}

#[test]
fn parser_rejects_uuid_versions_other_than_v7() {
    let error = RelayIdentifier::parse("550e8400-e29b-41d4-a716-446655440000")
        .expect_err("UUIDv4 must not enter the v7 identity boundary");

    assert_eq!(error, RelayIdentifierParseError::UnsupportedVersion);
}

#[test]
fn parser_rejects_non_rfc_variant_even_when_version_bits_are_seven() {
    let error = RelayIdentifier::parse("017f22e2-79b0-7cc3-c8c4-dc0c0c07398f")
        .expect_err("Microsoft-variant UUID must not enter the RFC 9562 boundary");

    assert_eq!(error, RelayIdentifierParseError::UnsupportedVariant);
}
