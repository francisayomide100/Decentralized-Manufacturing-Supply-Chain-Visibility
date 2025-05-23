;; Entity Verification Contract
;; This contract validates supply chain participants

(define-data-var admin principal tx-sender)

;; Entity types: 1 = Manufacturer, 2 = Supplier, 3 = Distributor, 4 = Retailer
(define-map entities
  { entity-id: (string-ascii 36) }
  {
    principal: principal,
    name: (string-ascii 64),
    entity-type: uint,
    verified: bool,
    verification-date: uint
  }
)

(define-read-only (get-entity (entity-id (string-ascii 36)))
  (map-get? entities { entity-id: entity-id })
)

(define-read-only (is-verified (entity-id (string-ascii 36)))
  (default-to false (get verified (get-entity entity-id)))
)

(define-public (register-entity
    (entity-id (string-ascii 36))
    (name (string-ascii 64))
    (entity-type uint))
  (begin
    (asserts! (and (>= entity-type u1) (<= entity-type u4)) (err u1))
    (asserts! (is-none (get-entity entity-id)) (err u2))
    (ok (map-set entities
      { entity-id: entity-id }
      {
        principal: tx-sender,
        name: name,
        entity-type: entity-type,
        verified: false,
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-entity (entity-id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (asserts! (is-some (get-entity entity-id)) (err u4))
    (ok (map-set entities
      { entity-id: entity-id }
      (merge (unwrap-panic (get-entity entity-id))
        {
          verified: true,
          verification-date: block-height
        }
      )
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3))
    (ok (var-set admin new-admin))
  )
)
