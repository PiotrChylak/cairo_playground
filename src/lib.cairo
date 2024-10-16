#[starknet::interface]
pub trait IGameBeta<TContractState> {
    fn initialize_position(ref self: TContractState);
    fn update_position(ref self: TContractState, x_change: felt252, y_change: felt252);
    fn get_position(self: @TContractState) -> (felt252, felt252);
    fn check_collisions(self: @TContractState, new_x: felt252, new_y: felt252) -> bool;

    fn initialize_map(ref self: TContractState, wall_points: Array<felt252>);
    fn get_wall_positions(self: @TContractState) -> Array<felt252>;
}

#[starknet::contract]
mod GameBeta { // use StoragePointerWriteAccess;
    use core::ops::SubAssign;
    use super::IGameBeta;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait
    };
    use core::iter::IntoIterator;

    #[derive(starknet::Store, Drop)]
    struct Coordinates {
        pub x_value: felt252,
        pub y_value: felt252,
    }

    #[derive(starknet::Store, Drop)]
    struct Player {
        coordinates: Coordinates,
        hp: felt252,
        dmg: felt252,
    }

    #[derive(starknet::Store, Drop)]
    struct Wall {
        pub coordinates: Coordinates
    }

    #[storage]
    struct Storage {
        player: Player,
        walls: Vec<Wall>,
    }

    #[abi(embed_v0)]
    impl GameBetaImpl of super::IGameBeta<ContractState> {
        fn initialize_position(ref self: ContractState) {
            self.player.coordinates.x_value.write(1);
            self.player.coordinates.y_value.write(1);
        }

        #[derive(TerminalEq)]
        fn initialize_map(ref self: ContractState, wall_points: Array<felt252>) {
            let num_walls = wall_points.len() / 2;
            let mut i = 0;
            // let mut temp_walls: Array<Wall> = array![];

            loop {
                if i >= num_walls {
                    break;
                }

                let x = *wall_points.at(2 * i);
                let y = *wall_points.at(2 * i + 1);

                let new_wall = Wall { coordinates: Coordinates { x_value: x, y_value: y, }, };

                // temp_walls.append(new_wall);
                self.walls.append().write(new_wall);
                i += 1;
            }
            //self.walls.write(temp_walls);
        }

        fn get_wall_positions(self: @ContractState) -> Array<felt252> {
            let walls_count = self.walls.len();
            let mut positions: Array<felt252> = array![];
            let mut i = 0;

            loop {
                if i >= walls_count {
                    break;
                }

                let wall = self.walls.at(i);
                let x = wall.coordinates.x_value.read();
                let y = wall.coordinates.y_value.read();

                positions.append(x);
                positions.append(y);

                i += 1;
            };

            positions
        }


        fn check_collisions(self: @ContractState, new_x: felt252, new_y: felt252) -> bool {
            let mut temp = false;
            let walls_len = self.walls.len(); // Get the number of walls
            let mut i = 0; // Initialize the index

            loop {
                if i >= walls_len {
                    break; // Exit the loop if we have iterated over all the walls
                }

                // Check if the wall's coordinates match the new position
                if self.walls.at(i).coordinates.x_value.read() == new_x
                    && self.walls.at(i).coordinates.y_value.read() == new_y {
                    temp = true;
                }

                i += 1; // Manually increment the index
            };

            temp // Return the result
        }


        fn update_position(ref self: ContractState, x_change: felt252, y_change: felt252) {
            if (x_change != 0 || y_change != 0) {
                let current_x = self.player.coordinates.x_value.read();
                let current_y = self.player.coordinates.y_value.read();

                let new_x = current_x + x_change;
                let new_y = current_y + y_change;

                if !self.check_collisions(new_x, new_y) {
                    self.player.coordinates.x_value.write(new_x);
                    self.player.coordinates.y_value.write(new_y);
                } else {// Handle the collision case (optional: log or return early)
                // For now, we just skip updating the position.
                }
            }
        }


        fn get_position(self: @ContractState) -> (felt252, felt252) {
            (self.player.coordinates.x_value.read(), self.player.coordinates.y_value.read())
        }
    }
}
