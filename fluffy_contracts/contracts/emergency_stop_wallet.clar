;; Emergency Stop Wallet Smart Contract
;; Allows owner to pause/unpause all withdrawals

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_PAUSED (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_TRANSFER_FAILED (err u103))

;; Data Variables
(define-data-var is-paused bool false)

;; Private Functions
(define-private (is-owner)
  (is-eq tx-sender CONTRACT_OWNER))

;; Read-only Functions
(define-read-only (get-paused-status)
  (var-get is-paused))

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender)))

(define-read-only (get-owner)
  CONTRACT_OWNER)

;; Public Functions

;; Pause all withdrawals (owner only)
(define-public (pause)
  (begin
    (asserts! (is-owner) ERR_OWNER_ONLY)
    (var-set is-paused true)
    (ok true)))

;; Unpause withdrawals (owner only)
(define-public (unpause)
  (begin
    (asserts! (is-owner) ERR_OWNER_ONLY)
    (var-set is-paused false)
    (ok true)))

;; Deposit STX to the wallet
(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) (err u104))
    (stx-transfer? amount tx-sender (as-contract tx-sender))))

;; Withdraw STX from the wallet (fails if paused)
(define-public (withdraw (amount uint))
  (begin
    ;; Check if contract is paused
    (asserts! (not (var-get is-paused)) ERR_PAUSED)
    ;; Check if amount is valid
    (asserts! (> amount u0) (err u105))
    ;; Check if contract has sufficient balance
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount) ERR_INSUFFICIENT_BALANCE)
    ;; Transfer STX from contract to sender
    (as-contract (stx-transfer? amount tx-sender tx-sender))))

;; Emergency withdraw for owner (works even when paused)
(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-owner) ERR_OWNER_ONLY)
    (asserts! (> amount u0) (err u105))
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount) ERR_INSUFFICIENT_BALANCE)
    (as-contract (stx-transfer? amount tx-sender CONTRACT_OWNER))))

;; Withdraw all funds for owner (works even when paused)
(define-public (emergency-withdraw-all)
  (let ((balance (stx-get-balance (as-contract tx-sender))))
    (begin
      (asserts! (is-owner) ERR_OWNER_ONLY)
      (asserts! (> balance u0) ERR_INSUFFICIENT_BALANCE)
      (as-contract (stx-transfer? balance tx-sender CONTRACT_OWNER)))))

;; Get user's deposit history (placeholder - would need more complex implementation)
(define-read-only (get-user-info (user principal))
  {
    paused: (var-get is-paused),
    contract-balance: (stx-get-balance (as-contract tx-sender)),
    is-owner: (is-eq user CONTRACT_OWNER)
  })