import "./ownable.tact";

message Stop_Time {
    seconds: Int;
}

trait Stoppable with Ownable {
    mint_blocked: Bool;
    time_passed: Int;

    owner: Address;

    receive("mint_enable") {
        self.onlyOwner();
        self.mint_blocked = true;
    }

    receive("mint_disable") {
        self.onlyOwner();
        self.mint_blocked = false;
    }

    receive(msg: Stop_Time) {
        self.onlyOwner();
        self.time_passed = now() + msg.seconds;
    }

    fun canMint() {
        require(self.mint_blocked == false, "mint is disabled");
        require(now() > self.time_passed, "mint is disabled to time");
    }

    get fun passedTime(): Bool {
        return now() > self.time_passed;
    }


}