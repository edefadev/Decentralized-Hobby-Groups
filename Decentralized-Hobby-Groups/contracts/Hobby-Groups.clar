;; Decentralized Hobby Groups - Interest-based communities with shared resource pools
;; Contract for managing hobby groups, memberships, and shared resource pools

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_GROUP_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_MEMBER (err u409))
(define-constant ERR_NOT_MEMBER (err u403))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_INVALID_AMOUNT (err u400))
(define-constant ERR_GROUP_FULL (err u429))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u405))
(define-constant ERR_ALREADY_VOTED (err u410))

;; Data Variables
(define-data-var group-counter uint u0)
(define-data-var proposal-counter uint u0)

;; Data Maps
(define-map groups
  { group-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    category: (string-ascii 30),
    creator: principal,
    member-count: uint,
    max-members: uint,
    entry-fee: uint,
    resource-pool: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map memberships
  { group-id: uint, member: principal }
  {
    joined-at: uint,
    contribution: uint,
    reputation: uint,
    is-active: bool
  }
)

(define-map proposals
  { proposal-id: uint }
  {
    group-id: uint,
    proposer: principal,
    title: (string-ascii 80),
    description: (string-ascii 300),
    amount: uint,
    recipient: principal,
    votes-for: uint,
    votes-against: uint,
    status: (string-ascii 10),
    created-at: uint,
    expires-at: uint
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: bool }
)

;; Read-only functions
(define-read-only (get-group (group-id uint))
  (map-get? groups { group-id: group-id })
)

(define-read-only (get-membership (group-id uint) (member principal))
  (map-get? memberships { group-id: group-id, member: member })
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-group-count)
  (var-get group-counter)
)

(define-read-only (is-member (group-id uint) (member principal))
  (match (get-membership group-id member)
    membership (get is-active membership)
    false
  )
)

(define-read-only (get-member-groups (member principal))
  (let ((groups-list (list)))
    ;; This would need to be implemented with a more complex iteration
    ;; For now, returning empty list as placeholder
    groups-list
  )
)

;; Public functions

;; Create a new hobby group
(define-public (create-group 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (category (string-ascii 30))
  (max-members uint)
  (entry-fee uint)
)
  (let ((group-id (+ (var-get group-counter) u1)))
    (asserts! (> max-members u0) ERR_INVALID_AMOUNT)
    (asserts! (>= entry-fee u0) ERR_INVALID_AMOUNT)
    
    (map-set groups
      { group-id: group-id }
      {
        name: name,
        description: description,
        category: category,
        creator: tx-sender,
        member-count: u1,
        max-members: max-members,
        entry-fee: entry-fee,
        resource-pool: entry-fee,
        created-at: block-height,
        is-active: true
      }
    )
    
    ;; Add creator as first member
    (map-set memberships
      { group-id: group-id, member: tx-sender }
      {
        joined-at: block-height,
        contribution: entry-fee,
        reputation: u100,
        is-active: true
      }
    )
    
    (var-set group-counter group-id)
    (ok group-id)
  )
)

;; Join an existing group
(define-public (join-group (group-id uint))
  (match (get-group group-id)
    group
    (begin
      (asserts! (get is-active group) ERR_GROUP_NOT_FOUND)
      (asserts! (not (is-member group-id tx-sender)) ERR_ALREADY_MEMBER)
      (asserts! (< (get member-count group) (get max-members group)) ERR_GROUP_FULL)
      (asserts! (>= (stx-get-balance tx-sender) (get entry-fee group)) ERR_INSUFFICIENT_FUNDS)
      
      ;; Transfer entry fee to contract
      (try! (stx-transfer? (get entry-fee group) tx-sender (as-contract tx-sender)))
      
      ;; Add membership
      (map-set memberships
        { group-id: group-id, member: tx-sender }
        {
          joined-at: block-height,
          contribution: (get entry-fee group),
          reputation: u50,
          is-active: true
        }
      )
      
      ;; Update group data
      (map-set groups
        { group-id: group-id }
        (merge group {
          member-count: (+ (get member-count group) u1),
          resource-pool: (+ (get resource-pool group) (get entry-fee group))
        })
      )
      
      (ok true)
    )
    ERR_GROUP_NOT_FOUND
  )
)

;; Leave a group
(define-public (leave-group (group-id uint))
  (match (get-membership group-id tx-sender)
    membership
    (match (get-group group-id)
      group
      (begin
        (asserts! (get is-active membership) ERR_NOT_MEMBER)
        
        ;; Deactivate membership
        (map-set memberships
          { group-id: group-id, member: tx-sender }
          (merge membership { is-active: false })
        )
        
        ;; Update group member count
        (map-set groups
          { group-id: group-id }
          (merge group {
            member-count: (- (get member-count group) u1)
          })
        )
        
        (ok true)
      )
      ERR_GROUP_NOT_FOUND
    )
    ERR_NOT_MEMBER
  )
)

;; Contribute additional funds to group resource pool
(define-public (contribute-to-pool (group-id uint) (amount uint))
  (match (get-membership group-id tx-sender)
    membership
    (match (get-group group-id)
      group
      (begin
        (asserts! (get is-active membership) ERR_NOT_MEMBER)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= (stx-get-balance tx-sender) amount) ERR_INSUFFICIENT_FUNDS)
        
        ;; Transfer contribution to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update membership contribution
        (map-set memberships
          { group-id: group-id, member: tx-sender }
          (merge membership {
            contribution: (+ (get contribution membership) amount),
            reputation: (+ (get reputation membership) (/ amount u1000))
          })
        )
        
        ;; Update group resource pool
        (map-set groups
          { group-id: group-id }
          (merge group {
            resource-pool: (+ (get resource-pool group) amount)
          })
        )
        
        (ok true)
      )
      ERR_GROUP_NOT_FOUND
    )
    ERR_NOT_MEMBER
  )
)

;; Create a spending proposal
(define-public (create-proposal 
  (group-id uint)
  (title (string-ascii 80))
  (description (string-ascii 300))
  (amount uint)
  (recipient principal)
)
  (match (get-membership group-id tx-sender)
    membership
    (match (get-group group-id)
      group
      (begin
        (asserts! (get is-active membership) ERR_NOT_MEMBER)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= amount (get resource-pool group)) ERR_INSUFFICIENT_FUNDS)
        
        (let ((proposal-id (+ (var-get proposal-counter) u1)))
          (map-set proposals
            { proposal-id: proposal-id }
            {
              group-id: group-id,
              proposer: tx-sender,
              title: title,
              description: description,
              amount: amount,
              recipient: recipient,
              votes-for: u0,
              votes-against: u0,
              status: "active",
              created-at: block-height,
              expires-at: (+ block-height u144) ;; 24 hours in blocks
            }
          )
          
          (var-set proposal-counter proposal-id)
          (ok proposal-id)
        )
      )
      ERR_GROUP_NOT_FOUND
    )
    ERR_NOT_MEMBER
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (match (get-proposal proposal-id)
    proposal
    (begin
      (asserts! (is-member (get group-id proposal) tx-sender) ERR_NOT_MEMBER)
      (asserts! (is-none (map-get? votes { proposal-id: proposal-id, voter: tx-sender })) ERR_ALREADY_VOTED)
      (asserts! (< block-height (get expires-at proposal)) ERR_UNAUTHORIZED)
      
      ;; Record vote
      (map-set votes
        { proposal-id: proposal-id, voter: tx-sender }
        { vote: vote-for }
      )
      
      ;; Update proposal vote counts
      (if vote-for
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal {
            votes-for: (+ (get votes-for proposal) u1)
          })
        )
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal {
            votes-against: (+ (get votes-against proposal) u1)
          })
        )
      )
      
      (ok true)
    )
    ERR_PROPOSAL_NOT_FOUND
  )
)

;; Execute approved proposal
(define-public (execute-proposal (proposal-id uint))
  (match (get-proposal proposal-id)
    proposal
    (match (get-group (get group-id proposal))
      group
      (begin
        (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_UNAUTHORIZED)
        (asserts! (>= block-height (get expires-at proposal)) ERR_UNAUTHORIZED)
        (asserts! (is-eq (get status proposal) "active") ERR_UNAUTHORIZED)
        
        ;; Transfer funds from contract to recipient
        (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))
        
        ;; Update proposal status
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal { status: "executed" })
        )
        
        ;; Update group resource pool
        (map-set groups
          { group-id: (get group-id proposal) }
          (merge group {
            resource-pool: (- (get resource-pool group) (get amount proposal))
          })
        )
        
        (ok true)
      )
      ERR_GROUP_NOT_FOUND
    )
    ERR_PROPOSAL_NOT_FOUND
  )
)